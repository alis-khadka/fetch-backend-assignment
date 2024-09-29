class PointsController < ApplicationController
    before_action :set_wallet, except: :home
    before_action :validate_params, only: :add

    def home
        render json: { message: 'Welcome to wallet api.' }, status: :ok
    end

    def add
        @transaction = @wallet.transactions.new(transaction_params)

        if @wallet.save
            head :ok
        else
            head :unprocessable_entity
        end
    end

    def spend
        points_to_spend = spend_points_params[:points].to_i

        if points_to_spend > @wallet.balance
            render plain: "Insufficient points in the wallet.", status: :bad_request
        else
            response = Transaction.spend(points_to_spend, @wallet)

            render json: response, status: :ok
        end
    end

    def balance
        response = Transaction.balance_by_payers(@wallet)

        render json: response, status: :ok
    end

    private
    def set_wallet
        @wallet = Wallet.find(params[:walled_id] || Wallet.first.id)
    end

    def transaction_params
        params.permit(:payer, :points, :timestamp)
    end

    def spend_points_params
        params.permit(:points)
    end

    def validate_params
        begin
            # Checking if timestamp is missing
            raise TransactionErrors::TimestampMissing if !transaction_params[:timestamp]

            # Checking if the timestamp value is parsable into datetime
            # This will raise Date::Error if it is unparsable
            DateTime.parse(transaction_params[:timestamp])

            # Checking if payer is missing or empty
            raise TransactionErrors::PayerMissingOrEmpty if !transaction_params[:payer] || transaction_params[:payer].empty?
        rescue Date::Error => error
            render plain: 'Invalid timestamp.', status: :bad_request and return
        rescue TransactionErrors::TimestampMissing
            render plain: 'Timestamp key is missing.', status: :bad_request and return
        rescue TransactionErrors::PayerMissingOrEmpty
            render plain: 'Payer is missing or empty.', status: :bad_request and return
        end
    end
end
