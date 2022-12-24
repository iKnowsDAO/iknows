
module iknows::topic_board {

    // use std::vector;
    use sui::object::{Self, ID, UID};
    // use std::option::{Self, Option};
    use std::string::{String};
    use sui::tx_context::{Self, TxContext};

    use sui::transfer;
    use sui::event::emit;

    use iknows::topic::{Self, Topic, TopicManagerCap};

    use sui::dynamic_object_field as dof;

    /// A generate Board for open topic
    struct Board<phantom T: key> has key {
        id: UID,
        total: u64,
        sequence: u64,
    }


    /// A listing for the board. Intermediary object which owns a topic
    struct Listing<phantom T: key + store> has key, store {
        id: UID,
        owner: address,
        price: u64,
        created_at: u64,
    }


    // ================ Events ================ //
    
    // Emitted when a new board is created
    struct BoardCreatedEvent<phantom T: key> has copy, drop {
        board_id: ID,
    }

    // Emitted when someone lists a topic on the Board<T>
    struct ListedEvent<phantom T> has copy, drop {
        topic_id: ID,
        owner: address,
        price: u64,
        created_at: u64,
    }

    // Emitted when someone unlists a topic from the Board<T>
    struct UnlistedEvent<phantom T> has copy, drop {
        topic_id: ID,
    }

    // Errors
    const ENotOwner: u64 = 0;

    // ================ Publishing =============== //
    fun init(ctx: &mut TxContext) {
        publish<Topic>(ctx);
    }

    fun publish<T: key + store>(ctx: &mut TxContext) {
        let id = object::new(ctx);
        emit(BoardCreatedEvent<T> { board_id: object::uid_to_inner(&id) });

        transfer::share_object(Board<T> { 
            id ,
            total: 0,
            sequence: 10000,
        });
    }

    // Admin 
    public entry fun create_board<T: key + store>(
        _cap: &TopicManagerCap, ctx: &mut TxContext) {
        publish<T>(ctx);
    }

    public entry fun create_topic_and_list(
        board: &mut Board<Topic>,
        title: String,
        detail: String,
        format: String,
        category: String,
        photos: vector<vector<u8>>,
        author_name: String,
        price: u64,
        ctx: &mut TxContext,
    ) {
        // let author = tx_context::sender(ctx);
        let topic = topic::new_topic(title, detail, format, category, photos, author_name, ctx);

        list_topic(board, topic, price, ctx);      
    }
    
    public entry fun list_topic(
        board: &mut Board<Topic>,
        topic: Topic,
        price: u64,
        ctx: &mut TxContext
    ) {
        let id = object::new(ctx);
        let topic_id = object::id(&topic);
        let owner = tx_context::sender(ctx);
        let created_at = tx_context::epoch(ctx);

        emit(ListedEvent<Topic> {
            topic_id,
            price,
            owner,
            created_at,
        });

        increment_total(board);
        increment_sequence(board);

        dof::add(&mut id, true, topic);
        dof::add(&mut board.id, topic_id, Listing<Topic> { id, price, owner, created_at });
    }

    public fun unlist_topic(
        board: &mut Board<Topic>,
        topic_id: ID,
        ctx: &mut TxContext,
    ): Topic {
        let Listing<Topic> { id, price: _, owner, created_at: _} = dof::remove<ID, Listing<Topic>>(&mut board.id, topic_id);
        let topic = dof::remove(&mut id, true);

        assert!(tx_context::sender(ctx) == owner, ENotOwner);

        emit(UnlistedEvent<Topic> {
            topic_id: object::id(&topic),
        });

        object::delete(id);

        topic
    }   

    public entry fun unlist_and_take(
        board: &mut Board<Topic>,
        topic_id: ID,
        ctx: &mut TxContext
    ) {
        let topic = unlist_topic(board, topic_id, ctx);

        transfer::transfer(topic, tx_context::sender(ctx));
    }

    // public entry fun add_topic_comment(open_store: &mut OpenTopicStore, topic_idx: u64, detail: String, format: String, ctx: &mut TxContext) {

    //     assert!(table::contains(&open_store.topics, topic_idx), ENOT_FOUND);

    //     let content = base::new_rich_text(detail, format);
    //     let topic_id = table::borrow(&open_store.topics, topic_idx);
    //     let comment = comment::new_comment(*topic_id, content, ctx);

    //     transfer::transfer(comment, tx_context::sender(ctx));
    // }

    // get the open topic store sequnece 
    public fun get_sequence<T: key>(board: &Board<T>): u64 {
        board.sequence
    }

    public fun get_total<T: key>(board: &Board<T>): u64 {
        board.total
    }

    fun increment_total<T: key>(board: &mut Board<T>) {
        board.total = board.total + 1;
    }

    fun decrement_total<T: key>(board: &mut Board<T>) {
        board.total = board.total - 1;
    }

    fun increment_sequence<T: key>(board: &mut Board<T>) {
        board.sequence = board.sequence + 1;
    }

    // public fun get_topic_from_topic_store(store: &TopicStore, inner_id: ID): &Topic {
    //     table::borrow(&store.topics, inner_id)
    // }

    // public fun is_empty_open_store(store: &OpenTopicStore): bool {
    //     table::is_empty(&store.topics)
    // }

    // public fun is_empty_topic_store(store: &TopicStore): bool {
    //     table::is_empty(&store.topics)
    // }

    // public fun listed_contains(store: &TopicStore, inner_id: ID): bool {
    //     table::contains(&store.topics, inner_id)
    // }

    #[test_only]
    public fun init_test(ctx: &mut TxContext) {
        publish<Topic>(ctx);
    }
}