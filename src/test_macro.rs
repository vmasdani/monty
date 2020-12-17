macro_rules! gen_struct {
    ($struct:ident { $($field_name:ident: $type: ty), * }) =>{
        #[derive(Identifiable, Queryable, Associations, Insertable, Debug, Serialize, Deserialize)]
        pub struct $struct {
            pub id: Option<i32>,
            pub created_at: Option<NaiveDateTime>,
            pub updated_at: Option<NaiveDateTime>,

            $(
                pub $field: $type,
            )*
        }

        // impl Trait for $struct {
        //     pub fn access_var(&mut self, var: bool) {
        //         self.var = var;
        //     }
        // }
    };
}

gen_struct! (MyStruct {
    test: Option<String>
});

fn make_struct () {
    let struc = MyStruct {
        
    };
}