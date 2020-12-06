use crate::schema::*;

#[derive(Identifiable, Queryable, Insertable, Debug, Serialize, Deserialize)]
pub struct Email {
    pub id: Option<i32>,
    pub email: Option<String>,
}

#[derive(Identifiable, Queryable, Insertable, Associations, Debug, Serialize, Deserialize)]
#[belongs_to(Email)]
pub struct Subscription {
    pub id: Option<i32>,
    pub email_id: Option<i32>,
    pub name: Option<String>,
    pub cost: Option<i32>,
}
