use diesel::{
    r2d2::{ConnectionManager, PooledConnection},
    SqliteConnection,
};

use crate::model::{Currencie, Interval};
use diesel::prelude::*;

pub fn populate(conn: PooledConnection<ConnectionManager<SqliteConnection>>) {
    // Populate currencies
    vec!["IDR", "USD"].into_iter().for_each(|currency_name| {
        use crate::schema::currencies::dsl::*;

        let found_currency = currencies
            .filter(name.eq(currency_name))
            .first::<Currencie>(&conn);

        match found_currency {
            Ok(_) => {
                println!("Currency {} found.", currency_name)
            }
            _ => {
                println!("Currency {} not found! Creating...", currency_name);

                let currency = Currencie {
                    id: None,
                    name: Some(String::from(currency_name)),
                    created_at: None,
                    updated_at: None
                };

                diesel::replace_into(currencies)
                    .values(&currency)
                    .execute(&conn);
            }
        }
    });

    // Populate Interval
    vec!["Day", "Week", "Month", "Year"]
        .into_iter()
        .for_each(|interval_name| {
            use crate::schema::intervals::dsl::*;

            let found_interval = intervals
                .filter(name.eq(interval_name))
                .first::<Interval>(&conn);

            match found_interval {
                Ok(_) => {
                    println!("Interval {} found.", interval_name)
                }
                _ => {
                    println!("Interval {} not found! Creating...", interval_name);
                    let interval = Interval {
                        id: None,
                        name: Some(String::from(interval_name)),
                        created_at: None,
                        updated_at: None
                    };
                    diesel::replace_into(intervals)
                        .values(&interval)
                        .execute(&conn);
                }
            }
        });
}
