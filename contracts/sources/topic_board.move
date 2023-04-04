
module iknows::topic_board {

    // use std::vector;
    use sui::object::{Self, ID, UID};
    // use std::option::{Self, Option};
    use std::string::{String};
    use sui::tx_context::{Self, TxContext};

    use sui::transfer;
    use sui::event::emit;

    use sui::dynamic_object_field as dof;

    use iknows::base;
    use iknows::topic::{Self, Topic, TopicManagerCap};
    use iknows::comment::{Self, Comment};
    use iknows::reply::{Self, Reply}; 

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
        item_id: ID,
        owner: address,
        price: u64,
        created_at: u64,
    }

    // Emitted when someone unlists a topic from the Board<T>
    struct UnlistedEvent<phantom T> has copy, drop {
        item_id: ID,
    }

    // Errors
    const ENotOwner: u64 = 0;
    const ENotListed: u64 = 1;

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
        
        list<Topic>(board, topic, price, ctx);
        
        increment_total(board);
        increment_sequence(board);
    }

    public fun unlist_topic(
        board: &mut Board<Topic>,
        topic_id: ID,
        ctx: &mut TxContext,
    ): Topic {
        let topic = unlist<Topic>(board, topic_id, ctx);

        decrement_total(board);

        topic
    }   

    public fun unlist<T: key + store>(
        board: &mut Board<Topic>,
        item_id: ID,
        ctx: &mut TxContext,
    ): T {
        let Listing<T> { id, price: _, owner, created_at: _} = dof::remove<ID, Listing<T>>(&mut board.id, item_id);
        let topic = dof::remove(&mut id, true);

        assert!(tx_context::sender(ctx) == owner, ENotOwner);

        emit(UnlistedEvent<Topic> {
            item_id: object::id(&topic),
        });

        object::delete(id);

        topic
    }   

    public entry fun unlist_and_take_topic(
        board: &mut Board<Topic>,
        topic_id: ID,
        ctx: &mut TxContext
    ) {
        let topic = unlist_topic(board, topic_id, ctx);

        transfer::public_transfer(topic, tx_context::sender(ctx));
    }

    public entry fun unlist_and_take<T: key + store>(
        board: &mut Board<Topic>,
        topic_id: ID,
        ctx: &mut TxContext
    ) {
        let topic = unlist<T>(board, topic_id, ctx);

        transfer::public_transfer(topic, tx_context::sender(ctx));
    }

    public entry fun add_topic_comment(
        board: &mut Board<Topic>, 
        topic_id: ID, 
        detail: String, 
        format: String, 
        price: u64, 
        ctx: &mut TxContext
    ) {

        // assert!(dof::exists_with_type<ID, Listing<Topic>>(&board.id, topic_id), ENotListed);

        let content = base::new_rich_text(detail, format);
        let comment = comment::new_comment(topic_id, content, ctx);
        let comment_id = object::id(&comment);

        let id = object::new(ctx);
        let owner = tx_context::sender(ctx);
        let created_at = tx_context::epoch(ctx);

        dof::add(&mut id, true, comment);
        dof::add(&mut board.id, comment_id, Listing<Comment> { id, price, owner, created_at });
    }

    public entry fun list<T: key + store>(
        board: &mut Board<Topic>,
        item: T,
        price: u64,
        ctx: &mut TxContext
    ) {
        let id = object::new(ctx);
        let item_id = object::id(&item);
        let owner = tx_context::sender(ctx);
        let created_at = tx_context::epoch(ctx);

        emit(ListedEvent<T> {
            item_id,
            price,
            owner,
            created_at,
        });

        dof::add(&mut id, true, item);
        dof::add(&mut board.id, item_id, Listing<T> { id, price, owner, created_at });
    }

    public entry fun add_comment_reply(
        board: &mut Board<Topic>, 
        topic_id: ID, 
        comment_id: ID,
        detail: String, 
        format: String, 
        price: u64, 
        ctx: &mut TxContext
    ) {

        // assert!(dof::exists_with_type<ID, Listing<Topic>>(&board.id, topic_id), ENotListed);

        let content = base::new_rich_text(detail, format);
        let reply = reply::new_reply(topic_id, comment_id, content, ctx);
        let reply_id = object::id(&reply);

        let id = object::new(ctx);
        let owner = tx_context::sender(ctx);
        let created_at = tx_context::epoch(ctx);

        dof::add(&mut id, true, reply);
        dof::add(&mut board.id, reply_id, Listing<Reply> { id, price, owner, created_at });
    }


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


    #[test_only]
    public fun init_test(ctx: &mut TxContext) {
        publish<Topic>(ctx);
    }
}