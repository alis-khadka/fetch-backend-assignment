class CreateTransactions < ActiveRecord::Migration[7.2]
  def change
    create_table :transactions do |t|
      t.belongs_to :wallet, null:false
      t.string :payer
      t.bigint :points
      t.integer :status, default: 0

      t.timestamps
    end
  end
end
