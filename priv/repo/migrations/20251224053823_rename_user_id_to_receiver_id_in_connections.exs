defmodule InterestSpotlight.Repo.Migrations.RenameUserIdToReceiverIdInConnections do
  use Ecto.Migration

  def change do
    # Drop existing indexes that reference user_id
    drop index(:connections, [:user_id])
    drop unique_index(:connections, [:requester_id, :user_id])

    # Rename the column
    rename table(:connections), :user_id, to: :receiver_id

    # Recreate indexes with new column name
    create index(:connections, [:receiver_id])
    create unique_index(:connections, [:requester_id, :receiver_id])
  end
end
