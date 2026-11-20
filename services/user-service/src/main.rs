#![expect(let_underscore_drop, reason = "Violated by macro expansion.")]
#![expect(
    clippy::redundant_type_annotations,
    reason = "Violated by macro expansion."
)]
#![expect(
    clippy::let_underscore_must_use,
    reason = "Violated by macro expansion."
)]

use {
    rocket::{
        Config, State, get,
        http::Status,
        launch, routes,
        serde::{Serialize, json::Json, uuid::Uuid},
    },
    sqlx::{FromRow, PgPool},
};

#[derive(Serialize)]
struct Health {
    status: &'static str,
}

#[derive(Serialize, FromRow)]
struct UserSummary {
    id: Uuid,
    email: String,
}

#[get("/health")]
const fn health() -> Json<Health> {
    Json(Health { status: "ok" })
}

#[get("/users")]
async fn list_users(db: &State<PgPool>) -> Result<Json<Vec<UserSummary>>, Status> {
    // TODO: Use compile-time checked macro.
    let users = sqlx::query_as(
        "SELECT id, email FROM users ORDER BY created_at LIMIT 100",
    )
    .fetch_all(&**db)
    .await
    .map_err(|_| Status::InternalServerError)?;

    Ok(Json(users))
}

#[launch]
async fn rocket() -> _ {
    let figment = Config::figment();
    let database_url = figment
        .extract_inner::<String>("databases.user_db.url")
        .expect("DATABASE_URL must be set.");

    let pool = PgPool::connect(&database_url)
        .await
        .expect("Failed to connect to database.");

    rocket::custom(figment)
        .manage(pool)
        .mount("/", routes![health, list_users])
}
