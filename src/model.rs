use chrono::{DateTime, NaiveDate, NaiveDateTime, Utc};

use crate::schema::*;

// macro_rules! gen_struct {
//     ($struct:ident { $($field_name:ident: $type: ty), * }) =>{
//         #[derive(Identifiable, Queryable, Associations, Insertable, Debug, Serialize, Deserialize)]
//         pub struct $struct {
//             pub id: Option<i32>,
//             pub created_at: Option<NaiveDateTime>,
//             pub updated_at: Option<NaiveDateTime>,

//             $(
//                 pub $field: $type,
//             )*
//         }

//         // impl Trait for $struct {
//         //     pub fn access_var(&mut self, var: bool) {
//         //         self.var = var;
//         //     }
//         // }
//     };
// }

// gen_struct!(
//     Email {
//         email: Option<String>,
//         currency_id: Option<i32>,
//         currencie_id: Option<i32>,
//     }
// );

#[derive(Identifiable, Queryable, Associations, Insertable, Debug, Serialize, Deserialize)]
#[belongs_to(Currencie)]
pub struct Email {
    pub id: Option<i32>,
    pub created_at: Option<NaiveDateTime>,
    pub updated_at: Option<NaiveDateTime>,
    pub email: Option<String>,
    pub currency_id: Option<i32>,
    pub currencie_id: Option<i32>,
}

#[derive(Identifiable, Queryable, Insertable, Associations, Debug, Serialize, Deserialize)]
#[belongs_to(Email)]
pub struct Subscription {
    pub id: Option<i32>,
    pub created_at: Option<NaiveDateTime>,
    pub updated_at: Option<NaiveDateTime>,
    pub email_id: Option<i32>,
    pub name: Option<String>,
    pub cost: Option<f32>,
    pub interval_id: Option<i32>,
    pub interval_amount: Option<i32>,
}

#[derive(Identifiable, Queryable, Insertable, Debug, Serialize, Deserialize)]
pub struct Interval {
    pub id: Option<i32>,
    pub created_at: Option<NaiveDateTime>,
    pub updated_at: Option<NaiveDateTime>,
    pub name: Option<String>,
}

#[derive(Identifiable, Queryable, Insertable, Debug, Serialize, Deserialize)]
pub struct Currencie {
    pub id: Option<i32>,
    pub created_at: Option<NaiveDateTime>,
    pub updated_at: Option<NaiveDateTime>,
    pub name: Option<String>,
    pub rate: Option<f32>,
    pub last_update_day: Option<NaiveDateTime>
}
 
// gen_struct!(
//     Currencie {
//         name: Option<String>,
//     }
// );
