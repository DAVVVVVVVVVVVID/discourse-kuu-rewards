import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import DButton from "discourse/ui-kit/d-button";
import { i18n } from "discourse-i18n";

export const QR_CODE_MAX_BYTES = 5 * 1024 * 1024;
const ACCEPTED_TYPES = "image/png,image/jpeg,image/webp";

// 收款码和其他字段一起提交给插件，不走 core 的上传（那样传上去的图片知道地址谁都能看）
export default class QrCodeInput extends Component {
  @tracked error;
  @tracked previewUrl;

  acceptedTypes = ACCEPTED_TYPES;

  willDestroy() {
    super.willDestroy(...arguments);
    this.#revokePreview();
  }

  @action
  pick(event) {
    const file = event.target.files[0];
    this.error = null;
    if (!file) {
      return;
    }

    if (!ACCEPTED_TYPES.split(",").includes(file.type)) {
      this.error = i18n("kuu_rewards.claim.qr_code_wrong_type");
      event.target.value = "";
      return;
    }

    if (file.size > QR_CODE_MAX_BYTES) {
      this.error = i18n("kuu_rewards.claim.qr_code_too_large");
      event.target.value = "";
      return;
    }

    this.#revokePreview();
    this.previewUrl = URL.createObjectURL(file);
    this.args.onChange(file);
  }

  @action
  remove() {
    this.#revokePreview();
    this.previewUrl = null;
    this.args.onChange(null);
  }

  #revokePreview() {
    if (this.previewUrl) {
      URL.revokeObjectURL(this.previewUrl);
    }
  }

  <template>
    <div class="kuu-rewards-qr-input">
      {{#if this.previewUrl}}
        <img
          alt={{i18n "kuu_rewards.claim.qr_code_preview"}}
          class="kuu-rewards-qr-input__preview"
          src={{this.previewUrl}}
        />
        <DButton
          class="btn-default btn-small kuu-rewards-qr-input__remove"
          @action={{this.remove}}
          @icon="xmark"
          @label="kuu_rewards.claim.remove_qr_code"
        />
      {{else}}
        <input
          accept={{this.acceptedTypes}}
          class="kuu-rewards-qr-input__file"
          type="file"
          {{on "change" this.pick}}
        />
      {{/if}}
      {{#if this.error}}
        <p class="kuu-rewards-qr-input__error">{{this.error}}</p>
      {{/if}}
    </div>
  </template>
}
