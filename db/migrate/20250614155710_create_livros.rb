class CreateLivros < ActiveRecord::Migration[7.2]
  def change
    create_table :livros do |t|
      t.string :name
      t.string :isbn
      t.text :description
      t.string :author

      t.timestamps
    end
  end
end
