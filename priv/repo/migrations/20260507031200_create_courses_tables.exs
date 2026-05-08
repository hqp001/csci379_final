defmodule Csci379Final.Repo.Migrations.CreateCoursesTables do
  use Ecto.Migration

  def change do
    create table(:stories) do
      add :title, :string, null: false
      add :topic, :string, null: false
      add :status, :string, null: false, default: "generating"
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:stories, [:user_id])

    create table(:chapters) do
      add :title, :string, null: false
      add :description, :text
      add :position, :integer, null: false
      add :story_id, references(:stories, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:chapters, [:story_id])

    create table(:scenes) do
      add :title, :string, null: false
      add :description, :text
      add :position, :integer, null: false
      add :is_locked, :boolean, null: false, default: true
      add :chapter_id, references(:chapters, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:scenes, [:chapter_id])

    create table(:quests) do
      add :type, :string, null: false
      add :question, :text, null: false
      add :options, :map
      add :correct_answer, :text, null: false
      add :explanation, :text
      add :position, :integer, null: false
      add :scene_id, references(:scenes, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:quests, [:scene_id])

    create table(:scene_completions) do
      add :xp_earned, :integer, null: false, default: 0
      add :completed_at, :utc_datetime, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :scene_id, references(:scenes, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:scene_completions, [:user_id])
    create index(:scene_completions, [:scene_id])
    create unique_index(:scene_completions, [:user_id, :scene_id])

    create table(:quest_attempts) do
      add :user_answer, :text, null: false
      add :is_correct, :boolean, null: false
      add :ai_feedback, :text
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :quest_id, references(:quests, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:quest_attempts, [:user_id])
    create index(:quest_attempts, [:quest_id])
  end
end
