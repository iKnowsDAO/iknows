
module iknows::topic {

    use std::vector;
    use sui::object::{Self, ID, UID};
    // use std::option::{Self, Option};
    use std::string::{Self, String};
    use sui::tx_context::{Self, TxContext};
    // use sui::coin::Coin;
    // use sui::sui::SUI;
    use sui::transfer;
    use sui::event::emit;
    use sui::object_table::{Self as ot, ObjectTable};

    // Resources
    struct Topic has key, store {
        id: UID,
        title: String,
        content: RichText,
        category: String,
        photos: vector<vector<u8>>,
        events: vector<String>,
        author: address,
        author_name: String,
        created_at: u64,
    }

    struct RichText has store, copy, drop {
        detail: String,
        format: String,
    }

    struct TopicBag<phantom K, phantom V> has key, store {
        id: UID,
        topics: ObjectTable<K, V>,
    }


    // Getters
    public fun title(t: &Topic): String {
        t.title
    }

    public fun content(t: &Topic): RichText {
        t.content
    }

    public fun category(t: &Topic): String {
        t.category
    }

    public fun photos(t: &Topic): vector<vector<u8>> {
        t.photos
    }

    public fun events(t: &Topic): vector<String> {
        t.events
    }

    public fun author(t: &Topic): address {
        t.author
    }

    public fun author_name(t: &Topic): String {
        t.author_name
    }

    public fun created_at(t: &Topic): u64 {
        t.created_at
    }
}