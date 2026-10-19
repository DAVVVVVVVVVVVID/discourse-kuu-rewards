import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import Form from "discourse/components/form";
import { ajax } from "discourse/lib/ajax";
import { extractError } from "discourse/lib/ajax-error";
import DButton from "discourse/ui-kit/d-button";
import DModal from "discourse/ui-kit/d-modal";
import { i18n } from "discourse-i18n";

export default class VoidClaim extends Component {
  @tracked flash;
  @tracked isSubmitting = false;

  formData = { reason: "" };

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
  async submit(data) {
    this.flash = null;
    this.isSubmitting = true;

    try {
      await ajax(
        `/kuu-rewards/admin/claims/${this.args.model.claim.id}/void.json`,
        { type: "PUT", data: { reason: data.reason.trim() } }
      );
      this.args.closeModal();
      this.args.model.onVoided();
    } catch (error) {
      this.flash = extractError(error);
    } finally {
      this.isSubmitting = false;
    }
  }

  <template>
    <DModal
      class="kuu-rewards-void-modal"
      @closeModal={{@closeModal}}
      @flash={{this.flash}}
      @flashType="error"
      @title={{i18n
        "kuu_rewards.admin.void_title"
        username=@model.claim.user.username
      }}
    >
      <:body>
        <p>{{i18n "kuu_rewards.admin.void_explanation"}}</p>
        <Form
          @data={{this.formData}}
          @onRegisterApi={{this.registerApi}}
          @onSubmit={{this.submit}}
          as |form|
        >
          <form.Field
            @format="full"
            @name="reason"
            @title={{i18n "kuu_rewards.admin.void_reason"}}
            @type="textarea"
            @validation="required:trim|length:1,500"
            as |field|
          >
            <field.Control @height={{80}} />
          </form.Field>
        </Form>
      </:body>

      <:footer>
        <DButton
          class="btn-danger kuu-rewards-void-modal__submit"
          @action={{this.submitForm}}
          @isLoading={{this.isSubmitting}}
          @label="kuu_rewards.admin.void"
        />
        <DButton class="btn-flat" @action={{@closeModal}} @label="cancel" />
      </:footer>
    </DModal>
  </template>
}
