class PointsController < ApplicationController
    before_action :set_wallet, except: :home
    before_action :validate_transaction_params, only: :add
    before_action :validate_spend_points_params, only: :spend

    def home
        render json: { message: "Welcome to wallet api." }, status: :ok
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
        @wallet = Wallet.find(params[:wallet_id] || Wallet.first.id)
    end

    def transaction_params
        params.permit(:payer, :points, :timestamp)
    end

    def spend_points_params
        params.permit(:points)
    end

    def validate_transaction_params
        begin
            # Checking if timestamp is missing
            raise TransactionErrors::TimestampMissing if !transaction_params[:timestamp]

            # Checking if the timestamp value is parsable into datetime
            # This will raise Date::Error if it is unparsable
            DateTime.parse(transaction_params[:timestamp])

            # Checking if payer is missing or empty
            raise TransactionErrors::PayerMissingOrEmpty if !transaction_params[:payer] || transaction_params[:payer].empty?

            # Checking if points is missing
            raise TransactionErrors::PointsMissing if !transaction_params[:points]

            # Checking if points is integer
            Integer(transaction_params[:points])

            # Checking if points is negative or zero
            raise TransactionErrors::NegativeOrZeroPointsValue if Integer(transaction_params[:points]) <= 0
        rescue Date::Error => error
            render plain: "Invalid timestamp.", status: :bad_request and return
        rescue TransactionErrors::TimestampMissing
            render plain: "Timestamp key is missing.", status: :bad_request and return
        rescue TransactionErrors::PayerMissingOrEmpty
            render plain: "Payer is missing or empty.", status: :bad_request and return
        rescue TransactionErrors::PointsMissing
            render plain: "Points is missing.", status: :bad_request and return
        rescue TypeError, ArgumentError
            render plain: "Points value should be integer.", status: :bad_request and return
        rescue TransactionErrors::NegativeOrZeroPointsValue
            render plain: "Points value cannot be negative or zero.", status: :bad_request and return
        end
    end

    def validate_spend_points_params
        begin
            # Checking if points is missing
            raise TransactionErrors::PointsMissing if !spend_points_params[:points]

            # Checking if points is integer
            Integer(spend_points_params[:points])

            # Checking if points is negative or zero
            raise TransactionErrors::NegativeOrZeroPointsValue if Integer(spend_points_params[:points]) <= 0
        rescue TransactionErrors::PointsMissing
            render plain: "Points is missing.", status: :bad_request and return
        rescue TypeError, ArgumentError
            render plain: "Points value should be integer.", status: :bad_request and return
        rescue TransactionErrors::NegativeOrZeroPointsValue
            render plain: "Points value cannot be negative or zero.", status: :bad_request and return
        end
    end
end
