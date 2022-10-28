
module iknows::users {

    use sui::object::UID;
    use std::string::String;

    struct UserProfile has key {
        id: UID,
        addr: address,
        name: String,
        bio: String,
        created_at: u64,
    }
}