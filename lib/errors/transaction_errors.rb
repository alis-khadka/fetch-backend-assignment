module TransactionErrors
    class TimestampMissing < StandardError; end

    class PayerMissingOrEmpty < StandardError; end
end