table! {
    currencies (id) {
        id -> Nullable<Integer>,
        name -> Nullable<Text>,
        created_at -> Nullable<Timestamp>,
    }
}

table! {
    emails (id) {
        id -> Nullable<Integer>,
        email -> Nullable<Text>,
        created_at -> Nullable<Timestamp>,
        currency_id -> Nullable<Integer>,
        currencie_id -> Nullable<Integer>,
    }
}

table! {
    intervals (id) {
        id -> Nullable<Integer>,
        name -> Nullable<Text>,
        created_at -> Nullable<Timestamp>,
    }
}

table! {
    intervals_subscriptions (id) {
        id -> Nullable<Integer>,
        interval_id -> Nullable<Integer>,
        subscription_id -> Nullable<Integer>,
        created_at -> Nullable<Timestamp>,
    }
}

table! {
    subscriptions (id) {
        id -> Nullable<Integer>,
        email_id -> Nullable<Integer>,
        name -> Nullable<Text>,
        cost -> Nullable<Float>,
        created_at -> Nullable<Timestamp>,
        interval_id -> Nullable<Integer>,
        interval_amount -> Nullable<Integer>,
    }
}

allow_tables_to_appear_in_same_query!(
    currencies,
    emails,
    intervals,
    intervals_subscriptions,
    subscriptions,
);
