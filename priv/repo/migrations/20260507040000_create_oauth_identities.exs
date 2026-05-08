defmodule Csci379Final.Repo.Migrations.CreateOauthIdentities do
  use Ecto.Migration

  def change do
    create table(:oauth_identities) do
      add :provider, :string, null: false
      add :uid, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:oauth_identities, [:user_id])
    create unique_index(:oauth_identities, [:provider, :uid])
  end
end
