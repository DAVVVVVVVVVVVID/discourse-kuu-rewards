# discourse-kuu-rewards（给 Claude Code）

## 这是什么
- 京大中文论坛（KUU，京都大学学生论坛，Discourse 自托管）的点赞奖励插件，**只服务一次临时活动**：活动结束、奖金发完就卸载。不要为以后复用多做设计，能简单就简单
- 技术方案（规则和设计以它为准）：Notion「项目中心 › 项目文档 › 京大论坛｜点赞奖励插件技术方案」
  https://app.notion.com/p/3fe43ea2113c81138b9cf5d00a9594ac 。开发前先读；纯技术细节自己定，写进这份方案并在改动处写上日期
- 参考实现：同一作者的其他插件，都在 `~/discourse/plugins/` 下（`discourse-kuu-market` 最新，另有 `discourse-kuu-ratings`、`discourse-kuu-kyoto-email`、`discourse-kuu-new-topic`）。**这些插件都不要改**
- 线上部署不归本仓库管，由 KUU 运维那边负责（私有仓库 `kuu-forum`，Windows 上的 `D:\PROJECT\KUU`）。本仓库只负责写部署说明，由 David 转交
- 本仓库是**公开**的：不要提交任何密钥、敏感信息、用户数据（尤其是收款信息）

## 已确定的规则（不要自行改，要改先问 David）
1. **单个帖子**收到的赞（core 的 `posts.like_count`）≥ 20 即达标。回复它的帖子、同一话题的其他楼层不算
2. 只算 **2026-10-20 00:00 日本时间**之后发的帖子；**20 份领完即止**，没有截止日期
3. **所有赞都有效**，不过滤点赞人
4. 参加的帖子：公开分类里的普通帖子（一楼、回复、评分短评都算）；**不算二手市场**（分类 ID 8）；管理人员分类、私信、已删除、被隐藏的不算；鲸仔账号（用户名 `鲸仔-AI智能体`，ID 2）的帖子不算
5. 每份 1000 日元，共 20 份；一个帖子只能领一次；每人最多 5 份
6. **提交收款信息的那一刻就算领奖完成**：名额立即减一，领奖人立即出现在公开名单上，**没有审核步骤**
7. 收款信息**只有管理员**能看（David 负责转账）
8. 奖励页公开显示**剩余份数**和**领奖名单**（用户名、获奖帖子链接、领奖时间）
9. 管理员可以「作废」一份：释放名额、从名单去掉、站内通知领奖人
10. 所有交互都在单独的奖励页 `/rewards` 上，**帖子上不加任何按钮**

收款方式：PayPay（ID 必填，收款码图片选填）或微信（收款码图片必填，微信号选填）。表单要让用户勾选同意：用户名和获奖帖子会公开显示；收款信息只用于这次发奖、只有管理员能看、活动结束后删除。

## 线上已知事实
- 线上 Discourse `2026.10.0-latest`，主题是第三方的 FKB Pro
- 只有京大邮箱能注册，所有用户至少信任等级 1
- 线上关掉了回复、私信的邮件通知，Brevo 每天只有 300 封额度。**本插件不发邮件**，只发站内通知
- 公开分类：闲聊广场 4、入学指南 5、生活手续 7、二手市场 8（不参加）、评分中心 9、评分对象 10、网站反馈 2；管理人员 3 只有管理员能看
- 「公开分类」按「匿名用户能看的分类」判断，不写死 ID；二手市场用站点设置排除

## 开发环境
- 本仓库位于 WSL 的 `~/discourse/plugins/discourse-kuu-rewards`，Discourse 源码在 `~/discourse`（官方仓库，不要改）
- 在 `~/discourse` 下执行：
  - `d/boot_dev`：启动容器；`d/shutdown_dev`：停止容器（不开发时停掉）
  - `d/dev`：启动开发服务器，打开 http://localhost:3000
  - `d/rspec plugins/discourse-kuu-rewards/spec`：跑本插件的测试
  - 加了数据库迁移后，先执行 `d/rake db:migrate`，再执行 `RAILS_ENV=test d/rake db:migrate`
  - lint 要在容器里跑：`d/exec bin/lint --fix <文件...>`，路径相对 `~/discourse`。rubocop 有 `corrected` 时再跑一遍，否则 CI 的 `stree check` 可能失败
- `d/` 脚本都用 `docker exec -it`。没有终端时会报 `the input device is not a TTY`，这一步直接失败，脚本却显示成功。要用 `script -qec '命令' /dev/null` 包一层
- **内存很紧**（本机 7.8GB，WSL 约 4.9GB）：开发服务器只开 1 个 worker：`script -qec 'docker exec -it -u discourse -w /src -e UNICORN_WORKERS=1 discourse_dev bin/dev' /dev/null`；浏览器（截图、system spec、QUnit）一次只开一个
- 测试库只有一个：不要同时跑两组 rspec（会死锁）
- system spec、QUnit 的环境问题（Playwright 浏览器、前端构建、借用 Chromium 跑 QUnit）见 `discourse-kuu-market` 和 `discourse-kuu-new-topic` 的 `CLAUDE.md`
- 其他 KUU 插件会一起加载
- `plugin.rb` 的 `required_version` 保持 `2026.1.0`，**不要写当前版本号**：`2026.10.0-latest` 按版本比较规则比 `2026.10.0` 低，写高了插件不会被激活
- 插件总开关是站点设置 `kuu_rewards_enabled`，默认关闭，开发环境要在后台打开

## 约定
- 插件名 `discourse-kuu-rewards`，Ruby 模块 `DiscourseKuuRewards`，页面路由 `/rewards`，接口挂在 `/kuu-rewards`，站点设置都以 `kuu_rewards_` 开头
- 代码标识符用英文；面向用户的文案放在 `config/locales/`（zh_CN 和 en 都要有）
- 跟着 Discourse 官方插件的写法走：前端用 Glimmer 组件（.gjs），**不要改 core**
- 每个功能都要写测试：后端用 RSpec，页面和表单用 system spec
- 提交信息用中文；推送前先跑测试
- **main 必须随时能上线**：推送后 main 上的 GitHub CI 要全部通过；改了数据库的话 annotations_tests 也要过（跑一次 annotate）
- 部署到线上（改服务器 `app.yml`、rebuild）由 KUU 那边负责，必须先得到 David 的同意。部署说明里不要替 David 表态
- 用中文交流
