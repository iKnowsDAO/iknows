
module iknows::reply {

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
    struct Reply has key, store {
        id: UID,
        topic_id: ID,
        comment_id: ID,
        content: RichText,
        author: address,
        created_at: u64,
    }

    public fun new_reply(topic_id: ID, comment_id: ID, content: RichText, ctx: &mut TxContext): Reply {
        Reply {
            id: object::new(ctx),
            topic_id,
            comment_id,
            content,
            author: tx_context::sender(ctx),
            created_at: tx_context::epoch(ctx),
        }
    }

    public fun get_reply_id(reply: &Reply): ID {
        object::id(reply)
    }

    public fun get_reply(reply: &Reply): RichText{
        reply.content
    }

    public fun get_reply_author(reply: &Reply): address {
        reply.author
    }

    public fun get_reply_topic(reply: &Reply): ID {
        reply.topic_id
    }

    public fun get_reply_commnet(reply: &Reply): ID {
        reply.comment_id
    }
}