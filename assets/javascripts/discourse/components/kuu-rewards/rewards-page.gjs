import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import moment from "moment";
import routeAction from "discourse/helpers/route-action";
import DButton from "discourse/ui-kit/d-button";
import DUserLink from "discourse/ui-kit/d-user-link";
import dBoundAvatarTemplate from "discourse/ui-kit/helpers/d-bound-avatar-template";
import dFormatDate from "discourse/ui-kit/helpers/d-format-date";
import { i18n } from "discourse-i18n";
import ClaimForm from "./modal/claim-form";
import PostLink from "./post-link";

export default class RewardsPage extends Component {
  @service modal;
  @service router;

  get blockedMessage() {
    const reason = this.args.data.me?.blocked_reason;
    if (reason === "user_limit") {
      return i18n("kuu_rewards.me.user_limit", {
        count: this.args.data.per_user_limit,
      });
    }
  }

  get canClaim() {
    const me = this.args.data.me;
    return !!me && !me.blocked_reason && me.claimable_posts.length > 0;
  }

  get rules() {
    const data = this.args.data;
    return i18n("kuu_rewards.page.rules", {
      start: moment(data.start_at).format("LL"),
      threshold: data.like_threshold,
      amount: data.amount,
      total: data.total,
      limit: data.per_user_limit,
    });
  }

  get soldOut() {
    return this.args.data.remaining === 0;
  }

  @action
  claimStatus(claim) {
    if (claim.voided_at) {
      return i18n("kuu_rewards.me.status.voided", {
        reason: claim.void_reason,
      });
    }
    return claim.transferred_at
      ? i18n("kuu_rewards.me.status.transferred")
      : i18n("kuu_rewards.me.status.pending");
  }

  @action
  openClaimForm() {
    this.modal.show(ClaimForm, {
      model: {
        posts: this.args.data.me.claimable_posts,
        onClaimed: () => this.router.refresh(),
      },
    });
  }

  <template>
    <div class="kuu-rewards">
      <header class="kuu-rewards__header">
        <h1 class="kuu-rewards__title">{{i18n "kuu_rewards.page.title"}}</h1>
        <p class="kuu-rewards__rules">{{this.rules}}</p>
        <details class="kuu-rewards__details">
          <summary>{{i18n "kuu_rewards.page.details_title"}}</summary>
          <ul>
            <li>{{i18n "kuu_rewards.page.details.posts"}}</li>
            <li>{{i18n "kuu_rewards.page.details.likes"}}</li>
            <li>{{i18n "kuu_rewards.page.details.excluded"}}</li>
            <li>{{i18n "kuu_rewards.page.details.claim"}}</li>
            <li>{{i18n "kuu_rewards.page.details.void"}}</li>
          </ul>
        </details>
      </header>

      <section class="kuu-rewards__remaining">
        {{#if this.soldOut}}
          <p class="kuu-rewards__sold-out">{{i18n
              "kuu_rewards.page.sold_out"
            }}</p>
        {{else}}
          <p class="kuu-rewards__remaining-label">
            {{i18n "kuu_rewards.page.remaining_label"}}
          </p>
          <p class="kuu-rewards__remaining-count">
            <strong>{{@data.remaining}}</strong>
            /
            {{i18n "kuu_rewards.page.total" count=@data.total}}
          </p>
        {{/if}}
      </section>

      {{#if @data.me}}
        <section class="kuu-rewards__me">
          {{#if this.canClaim}}
            <div class="kuu-rewards__eligible">
              <p class="kuu-rewards__eligible-message">
                {{i18n "kuu_rewards.me.eligible"}}
              </p>
              <DButton
                class="btn-primary btn-large kuu-rewards__claim"
                @action={{this.openClaimForm}}
                @icon="gift"
                @label="kuu_rewards.me.claim"
              />
            </div>
          {{else if this.blockedMessage}}
            <p class="kuu-rewards__blocked">{{this.blockedMessage}}</p>
          {{else if this.soldOut}}
            {{! 全站领完时上面已经说明 }}
          {{else}}
            <h2>{{i18n "kuu_rewards.me.progress_title"}}</h2>
            {{#if @data.me.progress_posts.length}}
              <ul class="kuu-rewards__progress">
                {{#each @data.me.progress_posts as |post|}}
                  <li class="kuu-rewards__progress-item">
                    <PostLink @post={{post}} />
                    <progress
                      class="kuu-rewards__progress-bar"
                      max={{@data.like_threshold}}
                      value={{post.like_count}}
                    ></progress>
                    <span class="kuu-rewards__progress-count">
                      {{i18n
                        "kuu_rewards.me.progress"
                        count=post.like_count
                        threshold=@data.like_threshold
                      }}
                    </span>
                  </li>
                {{/each}}
              </ul>
            {{else}}
              <p class="kuu-rewards__empty">{{i18n
                  "kuu_rewards.me.no_posts"
                }}</p>
            {{/if}}
          {{/if}}

          {{#if @data.me.claims.length}}
            <h2>{{i18n "kuu_rewards.me.claims_title"}}</h2>
            <ul class="kuu-rewards__my-claims">
              {{#each @data.me.claims as |claim|}}
                <li class="kuu-rewards__my-claim">
                  <PostLink @post={{claim.post}} />
                  <span class="kuu-rewards__my-claim-date">
                    {{dFormatDate claim.claimed_at format="medium"}}
                  </span>
                  <span class="kuu-rewards__my-claim-status">
                    {{this.claimStatus claim}}
                  </span>
                </li>
              {{/each}}
            </ul>
          {{/if}}
        </section>
      {{else}}
        <section class="kuu-rewards__me">
          <p>{{i18n "kuu_rewards.me.login_hint"}}</p>
          <DButton
            class="btn-primary"
            @action={{routeAction "showLogin"}}
            @label="log_in"
          />
        </section>
      {{/if}}

      <section class="kuu-rewards__winners">
        <h2>{{i18n "kuu_rewards.winners.title"}}</h2>
        {{#if @data.winners.length}}
          <ul class="kuu-rewards__winner-list">
            {{#each @data.winners as |winner|}}
              <li class="kuu-rewards__winner">
                <DUserLink
                  class="kuu-rewards__winner-user"
                  @username={{winner.username}}
                >
                  {{dBoundAvatarTemplate winner.avatar_template "small"}}
                  {{winner.username}}
                </DUserLink>
                <PostLink @post={{winner.post}} />
                <span class="kuu-rewards__winner-date">
                  {{dFormatDate winner.claimed_at format="medium"}}
                </span>
              </li>
            {{/each}}
          </ul>
        {{else}}
          <p class="kuu-rewards__empty">{{i18n "kuu_rewards.winners.empty"}}</p>
        {{/if}}
      </section>
    </div>
  </template>
}
