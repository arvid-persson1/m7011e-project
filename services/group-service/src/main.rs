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
        State, build, get,
        http::Status,
        launch, routes,
        serde::{Serialize, json::Json},
    },
    sqlx::{FromRow, PgPool, query_as},
    std::env::var as env_var,
};

#[derive(Serialize)]
struct Health {
    status: &'static str,
}

#[derive(Serialize, FromRow)]
struct Group {
    name: String,
}

#[get("/health")]
const fn health() -> Json<Health> {
    Json(Health { status: "ok" })
}

#[get("/users")]
async fn list_groups(db: &State<PgPool>) -> Result<Json<Vec<Group>>, Status> {
    // TODO: Use compile-time checked macro.
    let groups = query_as("SELECT name FROM groups LIMIT 100")
        .fetch_all(&**db)
        .await
        .map_err(|_| Status::InternalServerError)?;

    Ok(Json(groups))
}

#[launch]
async fn rocket() -> _ {
    // NOTE: Does not exist at compile time; `env` macro can't be used.
    let database_url = env_var("DATABASE_URL").expect("DATABASE_URL must be set");
    let pool = PgPool::connect(&database_url)
        .await
        .expect("failed to connect to database");

    build().manage(pool).mount("/", routes![health, list_groups])
}
