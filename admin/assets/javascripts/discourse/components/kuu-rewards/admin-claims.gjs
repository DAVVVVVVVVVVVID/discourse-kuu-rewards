import Component from "@glimmer/component";
import { fn } from "@ember/helper";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { not } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DUserLink from "discourse/ui-kit/d-user-link";
import dFormatDate from "discourse/ui-kit/helpers/d-format-date";
import { i18n } from "discourse-i18n";
import VoidClaim from "./modal/void-claim";

export default class AdminClaims extends Component {
  @service dialog;
  @service modal;
  @service router;

  get hasPaymentInfo() {
    return this.args.claims.some(
      (claim) => claim.payment_account || claim.qr_code_url
    );
  }

  @action
  paymentMethod(claim) {
    return i18n(`kuu_rewards.payment_methods.${claim.payment_method}`);
  }

  @action
  async setTransferred(claim, transferred) {
    try {
      await ajax(`/kuu-rewards/admin/claims/${claim.id}/transferred.json`, {
        type: "PUT",
        data: { transferred },
      });
      this.router.refresh();
    } catch (error) {
      popupAjaxError(error);
    }
  }

  @action
  void(claim) {
    this.modal.show(VoidClaim, {
      model: { claim, onVoided: () => this.router.refresh() },
    });
  }

  @action
  clearPaymentInfo() {
    this.dialog.deleteConfirm({
      message: i18n("kuu_rewards.admin.clear_confirm"),
      confirmButtonLabel: "kuu_rewards.admin.clear",
      didConfirm: async () => {
        try {
          await ajax("/kuu-rewards/admin/payment-info.json", {
            type: "DELETE",
          });
          this.router.refresh();
        } catch (error) {
          popupAjaxError(error);
        }
      },
    });
  }

  <template>
    <div class="kuu-rewards-admin">
      <div class="kuu-rewards-admin__actions">
        <DButton
          class="btn-danger kuu-rewards-admin__clear"
          @action={{this.clearPaymentInfo}}
          @disabled={{not this.hasPaymentInfo}}
          @icon="trash-can"
          @label="kuu_rewards.admin.clear"
        />
        <p class="kuu-rewards-admin__hint">{{i18n
            "kuu_rewards.admin.clear_hint"
          }}</p>
      </div>

      {{#if @claims.length}}
        <table class="d-table kuu-rewards-admin__table">
          <thead class="d-table__header">
            <tr class="d-table__row">
              <th class="d-table__header-cell">{{i18n
                  "kuu_rewards.admin.claimed_at"
                }}</th>
              <th class="d-table__header-cell">{{i18n
                  "kuu_rewards.admin.user"
                }}</th>
              <th class="d-table__header-cell">{{i18n
                  "kuu_rewards.admin.post"
                }}</th>
              <th class="d-table__header-cell">{{i18n
                  "kuu_rewards.admin.payment"
                }}</th>
              <th class="d-table__header-cell">{{i18n
                  "kuu_rewards.admin.status"
                }}</th>
              <th class="d-table__header-cell"></th>
            </tr>
          </thead>
          <tbody class="d-table__body">
            {{#each @claims as |claim|}}
              <tr
                class="d-table__row kuu-rewards-admin__row
                  {{if claim.voided_at '--voided'}}"
                data-claim-id={{claim.id}}
              >
                <td class="d-table__cell --overview">
                  {{dFormatDate claim.claimed_at format="medium"}}
                </td>
                <td class="d-table__cell --detail">
                  <DUserLink @username={{claim.user.username}}>
                    {{claim.user.username}}
                  </DUserLink>
                </td>
                <td class="d-table__cell --detail">
                  {{#if claim.post}}
                    <a href={{claim.post.url}}>{{claim.post.topic_title}}</a>
                    <div class="kuu-rewards-admin__likes">
                      {{i18n
                        "kuu_rewards.admin.likes"
                        at_claim=claim.like_count
                        now=claim.post.like_count
                      }}
                      {{#if claim.post.deleted}}
                        <span class="kuu-rewards-admin__flag">{{i18n
                            "kuu_rewards.admin.deleted"
                          }}</span>
                      {{/if}}
                      {{#if claim.post.hidden}}
                        <span class="kuu-rewards-admin__flag">{{i18n
                            "kuu_rewards.admin.hidden"
                          }}</span>
                      {{/if}}
                    </div>
                  {{else}}
                    {{i18n "kuu_rewards.post_unavailable"}}
                  {{/if}}
                </td>
                <td class="d-table__cell --detail kuu-rewards-admin__payment">
                  <div>{{this.paymentMethod claim}}</div>
                  {{#if claim.payment_account}}
                    <div
                      class="kuu-rewards-admin__account"
                    >{{claim.payment_account}}</div>
                  {{/if}}
                  {{#if claim.qr_code_url}}
                    <a
                      class="kuu-rewards-admin__qr-code"
                      href={{claim.qr_code_url}}
                      rel="noopener noreferrer"
                      target="_blank"
                    >
                      <img
                        alt={{i18n "kuu_rewards.admin.qr_code"}}
                        src={{claim.qr_code_url}}
                      />
                    </a>
                  {{/if}}
                </td>
                <td class="d-table__cell --detail kuu-rewards-admin__status">
                  {{#if claim.voided_at}}
                    {{i18n
                      "kuu_rewards.admin.voided"
                      username=claim.voided_by
                      reason=claim.void_reason
                    }}
                  {{else if claim.transferred_at}}
                    {{i18n "kuu_rewards.admin.transferred"}}
                    {{dFormatDate claim.transferred_at format="medium"}}
                  {{else}}
                    {{i18n "kuu_rewards.admin.pending"}}
                  {{/if}}
                </td>
                <td class="d-table__cell --controls">
                  {{#unless claim.voided_at}}
                    <div class="d-table__cell-actions">
                      {{#if claim.transferred_at}}
                        <DButton
                          class="btn-default btn-small kuu-rewards-admin__undo-transferred"
                          @action={{fn this.setTransferred claim false}}
                          @label="kuu_rewards.admin.undo_transferred"
                        />
                      {{else}}
                        <DButton
                          class="btn-primary btn-small kuu-rewards-admin__mark-transferred"
                          @action={{fn this.setTransferred claim true}}
                          @icon="check"
                          @label="kuu_rewards.admin.mark_transferred"
                        />
                      {{/if}}
                      <DButton
                        class="btn-danger btn-small kuu-rewards-admin__void"
                        @action={{fn this.void claim}}
                        @icon="ban"
                        @label="kuu_rewards.admin.void"
                      />
                    </div>
                  {{/unless}}
                </td>
              </tr>
            {{/each}}
          </tbody>
        </table>
      {{else}}
        <p class="kuu-rewards-admin__empty">{{i18n
            "kuu_rewards.admin.empty"
          }}</p>
      {{/if}}
    </div>
  </template>
}
