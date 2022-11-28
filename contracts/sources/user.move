
module iknows::user {

    use sui::object::{Self, ID, UID};
    // use std::option::{Self, Option};
    use std::string::{Self, String};
    use sui::tx_context::{Self, TxContext};
    // use sui::coin::Coin;
    // use sui::sui::SUI;
    use sui::transfer;
    use sui::event::emit;


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

        transfer::transfer(u, sender);
    }

    /// entry fun
    // public entry fun create_user_without_avatar_url(
    //     nickname: vector<u8>, 
    //     birthday: vector<u8>, 
    //     avatar: vector<u8>, 
    //     language: vector<u8>, 
    //     gender: vector<u8>,
    //     city: vector<u8>, 
    //     country: vector<u8>, 
    //     ilike: vector<u8>,
    //     bio: vector<u8>, 
    //     ctx: &mut TxContext
    // ) {
    //     create_user(nickname, birthday, avatar, option::none(), gender, language, city, country, ilike, bio, ctx);
    // }

    public entry fun update_user_name(user: &mut UserProfile, new_name: vector<u8>) {
        let name = string::utf8(new_name);
        user.name = name
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
}