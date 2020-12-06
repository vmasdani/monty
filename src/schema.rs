table! {
    emails (id) {
        id -> Nullable<Integer>,
        email -> Nullable<Text>,
    }
}

table! {
    subscriptions (id) {
        id -> Nullable<Integer>,
        email_id -> Nullable<Integer>,
        name -> Nullable<Text>,
        cost -> Nullable<Integer>,
    }
}

allow_tables_to_appear_in_same_query!(
    emails,
    subscriptions,
);
