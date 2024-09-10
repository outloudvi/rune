use database::actions::file::get_ordered_files_by_ids;
use log::error;
use log::info;
use rinf::DartSignal;
use std::sync::Arc;
use tokio::sync::Mutex;

use database::actions::recommendation::get_recommendation_by_file_id;
use database::actions::recommendation::get_recommendation_by_percentile;
use database::connection::{MainDbConnection, RecommendationDbConnection};
use playback::player::Player;

use crate::common::Result;
use crate::files_to_playback_request;
use crate::messages::recommend::{PlaybackRecommendation, RecommendAndPlayRequest};
use crate::update_playlist;
use crate::RecommendAndPlayMixRequest;

pub async fn recommend_and_play_request(
    main_db: Arc<MainDbConnection>,
    recommend_db: Arc<RecommendationDbConnection>,
    lib_path: Arc<String>,
    player: Arc<Mutex<Player>>,
    dart_signal: DartSignal<RecommendAndPlayRequest>,
) -> Result<()> {
    let file_id = dart_signal.message.file_id;

    info!("Recommend and play for file: {}", file_id);

    let recommendations = match get_recommendation_by_file_id(&recommend_db, file_id, 30) {
        Ok(recs) => recs,
        Err(e) => {
            error!("Error getting recommendations: {:#?}", e);
            Vec::new()
        }
    };

    let recommendation_ids: Vec<i32> = recommendations.iter().map(|x| x.0 as i32).collect();

    let files = get_ordered_files_by_ids(&main_db, &recommendation_ids).await?;

    let requests = files_to_playback_request(&lib_path, files);
    update_playlist(&player, requests.clone()).await;

    let recommended_ids: Vec<i32> = requests.into_iter().map(|(id, _)| id).collect();
    PlaybackRecommendation { recommended_ids }.send_signal_to_dart();

    Ok(())
}

pub async fn recommend_and_play_mix_request(
    main_db: Arc<MainDbConnection>,
    recommend_db: Arc<RecommendationDbConnection>,
    lib_path: Arc<String>,
    player: Arc<Mutex<Player>>,
    dart_signal: DartSignal<RecommendAndPlayMixRequest>,
) -> Result<()> {
    let mix_id = dart_signal.message.mix_id;

    info!("Recommend and play for mix: {}", mix_id);

    let recommendations =
        match get_recommendation_by_percentile(&main_db, &recommend_db, 9, mix_id as usize).await {
            Ok(recs) => recs,
            Err(e) => {
                error!("Error getting mix: {:#?}", e);
                Vec::new()
            }
        };

    let recommendation_ids: Vec<i32> = recommendations.iter().map(|x| x.0 as i32).collect();

    let files = get_ordered_files_by_ids(&main_db, &recommendation_ids).await?;

    let requests = files_to_playback_request(&lib_path, files);
    update_playlist(&player, requests.clone()).await;

    let recommended_ids: Vec<i32> = requests.into_iter().map(|(id, _)| id).collect();
    PlaybackRecommendation { recommended_ids }.send_signal_to_dart();

    Ok(())
}
