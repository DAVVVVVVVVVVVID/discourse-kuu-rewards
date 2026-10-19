# frozen_string_literal: true

class CreateKuuRewardClaims < ActiveRecord::Migration[8.1]
  def change
    create_table :kuu_reward_claims do |t|
      t.integer :user_id, null: false
      t.integer :post_id, null: false
      t.integer :like_count, null: false
      t.string :payment_method, null: false
      t.string :payment_account
      t.binary :qr_code
      t.string :qr_code_content_type
      t.datetime :transferred_at
      t.datetime :voided_at
      t.integer :voided_by_id
      t.text :void_reason
      t.timestamps
    end

    # 作废的记录也留着，同一个帖子永远只能领一次
    add_index :kuu_reward_claims, :post_id, unique: true
    add_index :kuu_reward_claims, :user_id
  end
end
