
//! comment for the topic

module iknows::comment {

    // use std::vector;
    use sui::object::{Self, ID, UID};
    // use std::option::{Self, Option};
    // use std::string::{String};
    use sui::tx_context::{Self, TxContext};
    // use sui::coin::Coin;
    // use sui::sui::SUI;
    // use sui::transfer;
    // use sui::event::emit;
    // use sui::object_table::{Self as ot, ObjectTable};

    use iknows::base::RichText;

    // Resources
    struct Comment has key, store {
        id: UID,
        topic_id: ID,
        content: RichText,
        author: address,
        created_at: u64,
    }

    public fun new_comment(topic_id: ID, content: RichText, ctx: &mut TxContext): Comment {
        Comment {
            id: object::new(ctx),
            topic_id,
            content,
            author: tx_context::sender(ctx),
            created_at: tx_context::epoch(ctx),
        }
    }
}