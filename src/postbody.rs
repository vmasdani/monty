use crate::model::{Email, Subscription};

#[derive(Debug, Serialize, Deserialize)]
pub struct EmailPostBody {
    pub email: Email,
    pub subscriptions: Vec<Subscription>,
    pub subscription_delete_ids: Vec<i32>,
}
