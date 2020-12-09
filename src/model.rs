use crate::schema::*;

#[derive(Identifiable, Queryable, Associations, Insertable, Debug, Serialize, Deserialize)]
#[belongs_to(Currencie)]
pub struct Email {
    pub id: Option<i32>,
    pub email: Option<String>,
    pub currency_id: Option<i32>,
    pub currencie_id: Option<i32>,
}

#[derive(Identifiable, Queryable, Insertable, Associations, Debug, Serialize, Deserialize)]
#[belongs_to(Email)]
pub struct Subscription {
    pub id: Option<i32>,
    pub email_id: Option<i32>,
    pub name: Option<String>,
    pub cost: Option<i32>,
    pub interval_id: Option<i32>,
    pub interval_amount: Option<i32>
}

#[derive(Identifiable, Queryable, Insertable, Debug, Serialize, Deserialize)]
pub struct Interval {
    pub id: Option<i32>,
    pub name: Option<String>,
}

#[derive(Identifiable, Queryable, Insertable, Debug, Serialize, Deserialize)]
pub struct Currencie {
    pub id: Option<i32>,
    pub name: Option<String>,
}

