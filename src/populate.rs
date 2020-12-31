use chrono::{DateTime, NaiveDate, NaiveDateTime, Utc};
use diesel::{
    r2d2::{ConnectionManager, PooledConnection},
    SqliteConnection,
};

use crate::model::{Currencie, Interval};
use chrono::Datelike;
use diesel::prelude::*;

const currencies_list: [&str; 168] = [
    "AED", "AFN", "ALL", "AMD", "ANG", "AOA", "ARS", "AUD", "AWG", "AZN", "BAM", "BBD", "BDT",
    "BGN", "BHD", "BIF", "BMD", "BND", "BOB", "BRL", "BSD", "BTC", "BTN", "BWP", "BYN", "BYR",
    "BZD", "CAD", "CDF", "CHF", "CLF", "CLP", "CNY", "COP", "CRC", "CUC", "CUP", "CVE", "CZK",
    "DJF", "DKK", "DOP", "DZD", "EGP", "ERN", "ETB", "EUR", "FJD", "FKP", "GBP", "GEL", "GGP",
    "GHS", "GIP", "GMD", "GNF", "GTQ", "GYD", "HKD", "HNL", "HRK", "HTG", "HUF", "IDR", "ILS",
    "IMP", "INR", "IQD", "IRR", "ISK", "JEP", "JMD", "JOD", "JPY", "KES", "KGS", "KHR", "KMF",
    "KPW", "KRW", "KWD", "KYD", "KZT", "LAK", "LBP", "LKR", "LRD", "LSL", "LTL", "LVL", "LYD",
    "MAD", "MDL", "MGA", "MKD", "MMK", "MNT", "MOP", "MRO", "MUR", "MVR", "MWK", "MXN", "MYR",
    "MZN", "NAD", "NGN", "NIO", "NOK", "NPR", "NZD", "OMR", "PAB", "PEN", "PGK", "PHP", "PKR",
    "PLN", "PYG", "QAR", "RON", "RSD", "RUB", "RWF", "SAR", "SBD", "SCR", "SDG", "SEK", "SGD",
    "SHP", "SLL", "SOS", "SRD", "STD", "SVC", "SYP", "SZL", "THB", "TJS", "TMT", "TND", "TOP",
    "TRY", "TTD", "TWD", "TZS", "UAH", "UGX", "USD", "UYU", "UZS", "VEF", "VND", "VUV", "WST",
    "XAF", "XAG", "XAU", "XCD", "XDR", "XOF", "XPF", "YER", "ZAR", "ZMK", "ZMW", "ZWL",
];

pub fn populate(conn: PooledConnection<ConnectionManager<SqliteConnection>>) {
    // Print currencies
    // for i in currencies_list.iter() {
    //     println!("Curr: {}", i);
    // }

    // Populate currencies
    

    // Populate Interval
    vec![("Day", 28.0), ("Week", 4.0), ("Month", 1.0), ("Year", 1.0/12.0)]
        .into_iter()
        .for_each(|(interval_name, interval_modifier)| {
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
                        updated_at: None,
                        modifier: Some(interval_modifier)
                    };
                    diesel::replace_into(intervals)
                        .values(&interval)
                        .execute(&conn);
                }
            }
        });
}
