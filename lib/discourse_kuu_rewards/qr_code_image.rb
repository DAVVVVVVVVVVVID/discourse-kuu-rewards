# frozen_string_literal: true

module DiscourseKuuRewards
  # 收款码图片直接存在领奖记录里，不走 core 的上传：本地存储时上传的文件只要知道地址谁都能打开
  module QrCodeImage
    MAX_BYTES = 5.megabytes
    CONTENT_TYPES = { png: "image/png", jpeg: "image/jpeg", webp: "image/webp" }.freeze

    def self.valid?(file)
      content_type(file).present?
    end

    def self.content_type(file)
      return if !file.respond_to?(:path) || !file.respond_to?(:size) || file.size > MAX_BYTES

      CONTENT_TYPES[FastImage.type(file.path)]
    end
  end
end
