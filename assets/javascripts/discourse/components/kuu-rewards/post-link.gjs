import { i18n } from "discourse-i18n";

// 帖子被删、被移到私密分类后，后端不再给出帖子信息
const PostLink = <template>
  {{#if @post}}
    <a class="kuu-rewards-post-link" href={{@post.url}}>
      {{@post.topic_title}}
      {{#if (isReply @post)}}
        <span class="kuu-rewards-post-link__floor">
          {{i18n "kuu_rewards.post_number" number=@post.post_number}}
        </span>
      {{/if}}
    </a>
  {{else}}
    <span class="kuu-rewards-post-link --unavailable">
      {{i18n "kuu_rewards.post_unavailable"}}
    </span>
  {{/if}}
</template>;

function isReply(post) {
  return post.post_number > 1;
}

export default PostLink;
