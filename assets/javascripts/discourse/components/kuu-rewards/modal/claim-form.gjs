import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { extractError } from "discourse/lib/ajax-error";
import { eq } from "discourse/truth-helpers";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";
import PostLink from "../post-link";
import QrCodeInput from "../qr-code-input";

const PAYMENT_ACCOUNT_MAX_LENGTH = 100;

export default class ClaimForm extends Component {
  @service toasts;

  @tracked flash;
  @tracked isSubmitting = false;

  formData = {
    post_id: this.args.model.posts[0]?.id,
    payment_method: "paypay",
    payment_account: "",
    qr_code: null,
    agreed: false,
  };

  #formApi;

  @action
  registerApi(api) {
    this.#formApi = api;
  }

  @action
  submitForm() {
    this.#formApi.submit();
  }

  @action
  paymentAccountValidation(paymentMethod) {
    const length = `length:0,${PAYMENT_ACCOUNT_MAX_LENGTH}`;
    return paymentMethod === "paypay" ? `required:trim|${length}` : length;
  }

  @action
  qrCodeValidation(paymentMethod) {
    return paymentMethod === "wechat" ? "required" : null;
  }

  @action
  async submit(data) {
    this.flash = null;
    this.isSubmitting = true;

    const body = new FormData();
    body.append("post_id", data.post_id);
    body.append("payment_method", data.payment_method);
    body.append("payment_account", data.payment_account?.trim() ?? "");
    body.append("agreed", data.agreed ? "true" : "false");
    if (data.qr_code) {
      body.append("qr_code", data.qr_code);
    }

    try {
      await ajax("/kuu-rewards/claims.json", {
        type: "POST",
        data: body,
        processData: false,
        contentType: false,
      });

      this.args.closeModal();
      this.toasts.success({
        data: { message: i18n("kuu_rewards.claim.success") },
      });
      this.args.model.onClaimed();
    } catch (error) {
      this.flash = extractError(error);
    } finally {
      this.isSubmitting = false;
    }
  }

  <template>
    <DModal
      class="kuu-rewards-claim-modal"
      @closeModal={{@closeModal}}
      @flash={{this.flash}}
      @flashType="error"
      @title={{i18n "kuu_rewards.claim.title"}}
    >
      <:body>
        <Form
          class="kuu-rewards-claim-form"
          @data={{this.formData}}
          @onRegisterApi={{this.registerApi}}
          @onSubmit={{this.submit}}
          as |form data|
        >
          <form.Field
            @format="full"
            @name="post_id"
            @title={{i18n "kuu_rewards.claim.post"}}
            @type="radio-group"
            @validation="required"
            as |field|
          >
            <field.Control as |radioGroup|>
              {{#each @model.posts as |post|}}
                <radioGroup.Radio @value={{post.id}}>
                  <PostLink @post={{post}} />
                  <span class="kuu-rewards-claim-form__likes">
                    {{i18n "kuu_rewards.likes" count=post.like_count}}
                  </span>
                </radioGroup.Radio>
              {{/each}}
            </field.Control>
          </form.Field>

          <form.Field
            @format="full"
            @name="payment_method"
            @title={{i18n "kuu_rewards.claim.payment_method"}}
            @type="radio-group"
            @validation="required"
            as |field|
          >
            <field.Control as |radioGroup|>
              <radioGroup.Radio @value="paypay">
                {{i18n "kuu_rewards.payment_methods.paypay"}}
              </radioGroup.Radio>
              <radioGroup.Radio @value="wechat">
                {{i18n "kuu_rewards.payment_methods.wechat"}}
              </radioGroup.Radio>
            </field.Control>
          </form.Field>

          <form.Field
            @name="payment_account"
            @title={{if
              (eq data.payment_method "paypay")
              (i18n "kuu_rewards.claim.paypay_id")
              (i18n "kuu_rewards.claim.wechat_id")
            }}
            @type="input"
            @validation={{this.paymentAccountValidation data.payment_method}}
            as |field|
          >
            <field.Control />
          </form.Field>

          <form.Field
            @format="full"
            @helpText={{i18n "kuu_rewards.claim.qr_code_help"}}
            @name="qr_code"
            @title={{if
              (eq data.payment_method "paypay")
              (i18n "kuu_rewards.claim.paypay_qr_code")
              (i18n "kuu_rewards.claim.wechat_qr_code")
            }}
            @type="custom"
            @validation={{this.qrCodeValidation data.payment_method}}
            as |field|
          >
            <field.Control>
              <QrCodeInput @onChange={{field.set}} />
            </field.Control>
          </form.Field>

          <form.Field
            @format="full"
            @name="agreed"
            @title={{i18n "kuu_rewards.claim.agreement"}}
            @type="checkbox"
            @validation="accepted"
            as |field|
          >
            <field.Control />
          </form.Field>
        </Form>
      </:body>

      <:footer>
        <DButton
          class="btn-primary kuu-rewards-claim-modal__submit"
          @action={{this.submitForm}}
          @isLoading={{this.isSubmitting}}
          @label="kuu_rewards.claim.submit"
        />
        <DButton class="btn-flat" @action={{@closeModal}} @label="cancel" />
      </:footer>
    </DModal>
  </template>
}
