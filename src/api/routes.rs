use actix_web::web;

use super::handlers::{
    about,
    activities,
    activity_profile,
    activity_state,
    agent_profile,
    agents,
    statements,
    statements_more,
};
use super::middleware::{
    auth::AuthMiddleware,
    version_header::VersionHeaderMiddleware
};

pub fn configure(cfg: &mut web::ServiceConfig) {
    cfg.service(
        web::scope("/xapi")
            .wrap(VersionHeaderMiddleware)
            .wrap(AuthMiddleware)
            .route("/about", web::get().to(about::get))
            .service(
                web::resource("/statements")
                    .route(web::get().to(statements::get))
                    .route(web::post().to(statements::post))
                    .route(web::put().to(statements::put))
                    .route(web::head().to(statements::get)),
            )
            .route(
                "/statements/more/{more_id}",
                web::get().to(statements_more::get),
            )
            .service(
                web::resource("/activities/state")
                    .route(web::get().to(activity_state::get))
                    .route(web::post().to(activity_state::post))
                    .route(web::put().to(activity_state::put))
                    .route(web::delete().to(activity_state::delete))
                    .route(web::head().to(activity_state::get)),
            )
            .service(
                web::resource("/activities/profile")
                    .route(web::get().to(activity_profile::get))
                    .route(web::post().to(activity_profile::post))
                    .route(web::put().to(activity_profile::put))
                    .route(web::delete().to(activity_profile::delete))
                    .route(web::head().to(activity_profile::get)),
            )
            .route("/activities", web::get().to(activities::get))
            .service(
                web::resource("/agents/profile")
                    .route(web::get().to(agent_profile::get))
                    .route(web::post().to(agent_profile::post))
                    .route(web::put().to(agent_profile::put))
                    .route(web::delete().to(agent_profile::delete))
                    .route(web::head().to(agent_profile::get)),
            )
            .route("/agents", web::get().to(agents::get)),
    );
}