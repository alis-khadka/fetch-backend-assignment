module TransactionErrors
    class TimestampMissing < StandardError; end

    class PayerMissingOrEmpty < StandardError; end

    class PointsMissing < StandardError; end

    class InvalidPointsValue < StandardError; end
end