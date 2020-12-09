table! {
    currencies (id) {
        id -> Nullable<Integer>,
        name -> Nullable<Text>,
    }
}

table! {
    emails (id) {
        id -> Nullable<Integer>,
        email -> Nullable<Text>,
        currency_id -> Nullable<Integer>,
        currencie_id -> Nullable<Integer>,
    }
}

table! {
    intervals (id) {
        id -> Nullable<Integer>,
        name -> Nullable<Text>,
    }
}

table! {
    intervals_subscriptions (id) {
        id -> Nullable<Integer>,
        interval_id -> Nullable<Integer>,
        subscription_id -> Nullable<Integer>,
    }
}

table! {
    subscriptions (id) {
        id -> Nullable<Integer>,
        email_id -> Nullable<Integer>,
        name -> Nullable<Text>,
        cost -> Nullable<Integer>,
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
