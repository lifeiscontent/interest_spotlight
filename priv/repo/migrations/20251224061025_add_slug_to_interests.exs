defmodule InterestSpotlight.Repo.Migrations.AddSlugToInterests do
  use Ecto.Migration

  def up do
    alter table(:interests) do
      add :slug, :string
    end

    flush()

    # Populate slugs for existing interests
    execute """
    UPDATE interests
    SET slug = LOWER(REPLACE(REPLACE(TRIM(name), ' ', '-'), '--', '-'))
    """

    # Make slug not null after populating
    alter table(:interests) do
      modify :slug, :string, null: false
    end

    create unique_index(:interests, [:slug])
  end

  def down do
    drop index(:interests, [:slug])

    alter table(:interests) do
      remove :slug
    end
  end
end
