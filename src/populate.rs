use diesel::{
    r2d2::{ConnectionManager, PooledConnection},
    SqliteConnection,
};

pub fn populate(conn: PooledConnection<ConnectionManager<SqliteConnection>>) {
    // Populate currencies
    vec!["IDR", "USD"].into_iter().for_each(|currency_name| {});

    // Populate Interval
    vec!["Day", "Week", "Month", "Year"]
        .into_iter()
        .for_each(|interval_name| {});
}
