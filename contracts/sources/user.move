
module iknows::user {

    use std::vector;
    use sui::object::{Self, ID, UID};
    // use std::option::{Self, Option};
    use std::string::{Self, String};
    use sui::tx_context::{Self, TxContext};
    // use sui::coin::Coin;
    // use sui::sui::SUI;
    use sui::transfer;
    use sui::event::emit;
    use sui::object_bag::{Self as ob, ObjectBag};


    const Gender_Male: vector<u8> = b"male";
    const Gender_Female: vector<u8> = b"female";
    const Gender_Unknown: vector<u8> = b"secrecy";

    struct UserProfile has key {
        id: UID,
        sui_wallet: address,
        email: String,
        name: String,
        avatar: vector<u8>,
        birthday: String,
        gender: String,
        biography: String,
        interests: vector<String>,
        location: String,
        memo: String,
        created_at: u64,
    }

    struct UserRegistry has key {
        id: UID,
        bag: ObjectBag,
    }

    struct UserRegistered has key, store {
        id: UID,
        user_addr: address,
    }

    struct UserManagerCap has key, store {
        id: UID,
    }

    // Events
    struct UserRegistryCreatedEvent has copy, drop {
        registry_id: ID,
    }

    fun init(ctx: &mut TxContext) {
        init_cap(ctx);
        init_registry(ctx);
    }

    fun init_cap(ctx: &mut TxContext) {
        transfer::transfer(UserManagerCap { id: object::new(ctx) }, tx_context::sender(ctx));
    }

    fun init_registry(ctx: &mut TxContext) {
        let id = object::new(ctx);
        
        emit(UserRegistryCreatedEvent { registry_id: object::uid_to_inner(&id)});
              
        transfer::share_object(UserRegistry {
            id,
            bag: ob::new(ctx),
        });
    }

    public fun create_user(
        email: String,
        name: String,
        avatar: vector<u8>,
        birthday: String,
        gender: String,
        biography: String,
        interests: vector<String>,
        location: String,
        memo: String,
        ctx: &mut TxContext,
    ): UserProfile {
        let sender = tx_context::sender(ctx);
        let id = object::new(ctx);
        let gender = format_gender(&gender);
        let created_at = tx_context::epoch(ctx);

        UserProfile {
            id,
            sui_wallet: sender,
            email,
            name,
            avatar,
            birthday,
            gender,
            biography,
            interests,
            location,
            memo,
            created_at,
        }
    }

    public entry fun register(
        registry: &mut UserRegistry,
        email: String,
        name: String,
        avatar: vector<u8>,
        birthday: String,
        gender: String,
        biography: String,
        interests: vector<String>,
        location: String,
        memo: String,
        ctx: &mut TxContext,
    ) {
        let sender = tx_context::sender(ctx);
        let u = create_user(email, name, avatar, birthday, gender, biography, interests, location, memo, ctx);

        let ui = UserRegistered {
            id: object::new(ctx),
            user_addr: sender,
        };

        ob::add(&mut registry.bag, sender, ui);

        transfer::transfer(u, sender);
    }

    public entry fun register_with_name(registry: &mut UserRegistry, name: String, ctx: &mut TxContext) {
        register(registry, empty_string(), name, b"", empty_string(), empty_string(), empty_string(), vector::empty(), empty_string(), empty_string(), ctx);
    }

    public entry fun update_user_name(user: &mut UserProfile, registry: & UserRegistry, new_name: vector<u8>, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);

        if (ob::contains(&registry.bag, sender)) {
            let name = string::utf8(new_name);
            user.name = name
        } else {
            abort 0
        }
        
    }

    public entry fun update_user_avatar(user: &mut UserProfile, new_avatar: vector<u8>) {
        user.avatar = new_avatar
    }

    public entry fun update_user_birthday(user: &mut UserProfile, new_birthday: vector<u8>) {
        let birthday = string::utf8(new_birthday);
        user.birthday = birthday;
    }

    public entry fun update_user_biography(user: &mut UserProfile, new_bio: vector<u8>) {
        let bio = string::utf8(new_bio);
        user.biography = bio;
    }

    public entry fun transfer_user(user: UserProfile, to: address) {
        user.sui_wallet = to;
        transfer::transfer(user, to);
    }

    /// Getter 
    public fun name(user: &UserProfile): String {
        user.name
    }

    public fun birthday(user: &UserProfile): String {
        user.birthday
    }

    public fun sui_wallet(user: &UserProfile): address {
        user.sui_wallet
    }

    public fun avatar(user: &UserProfile): vector<u8> {
        user.avatar
    }


    public fun biography(user: &UserProfile): String {
        user.biography
    }

    public fun created_at(user: &UserProfile): u64 {
        user.created_at
    }

    public fun format_gender(gender: &String): String {
        let male = string::utf8(Gender_Male);
        let female = string::utf8(Gender_Female);
        let unknown = string::utf8(Gender_Unknown);

        if (gender == &female) {
            female
        } else if (gender == &male) {
            male
        } else {
            unknown
        }
    }

    public fun empty_string(): String {
        string::utf8(b"")
    }

    #[test_only] 
    public fun init_test(ctx: &mut TxContext) {
        init_cap(ctx);
        init_registry(ctx);
    }
}