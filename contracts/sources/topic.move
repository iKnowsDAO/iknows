
module iknows::topic {

    use std::vector;
    use sui::object::{Self, ID, UID};
    // use std::option::{Self, Option};
    use std::string::{String};
    use sui::tx_context::{Self, TxContext};
    // use sui::coin::Coin;
    // use sui::sui::SUI;
    use sui::transfer;
    use sui::event::emit;
    use sui::table::{Self, Table};
    // use sui::object_table::{Self as ot, ObjectTable};

    use iknows::base::{Self, RichText};
    use iknows::comment::{Self};

    // Resources
    struct Topic has key, store {
        id: UID,
        title: String,
        content: RichText,
        category: String,
        photos: vector<vector<u8>>,
        events: vector<TopicEvent>,
        author: address,
        author_name: String,
        created_at: u64,
    }

    struct TopicEvent has store, copy, drop {
        event_time: u64,
        description: String,
        created_at: u64,
    }

    // topic store for Individual
    struct TopicStore has key, store {
        id: UID,
        title: String,
        topics: Table<ID, Topic>,   // (idx, Topic)
        topics_listed: Table<ID, u64>,  // (topic id, idx in open topic store)
    }

    // open store for topic, everyone can access
    struct OpenTopicStore has key, store {
        id: UID,
        topics: Table<u64, ID>,     // idx, topic_id
        comments: Table<u64, ID>,   // idx, comment_id
        // replies: ObjectTable<ID, 
        sequence: u64,
    }

    struct TopicBrief has key, store {
        id: UID,
        topic_id: ID,
        topic_title: String,
        created_at: u64,
    }

    // Events
    struct TopicCreatedEvent has copy, drop {
        topic_id: ID,
        title: String,
        content: RichText,
        category: String,
        photos: vector<vector<u8>>,
        // events: vector<TopicEvent>,
        author: address,
        author_name: String,
        created_at: u64,
    }

    struct TopicUpdatedEvent has copy, drop {
        topic_id: ID,
        title: String,
        content: RichText,
        category: String,
        photos: vector<vector<u8>>,
        // events: vector<TopicEvent>,
        author_name: String,
        created_at: u64,
    }
    // Errors
    const ENOT_FOUND: u64 = 0;

    // Init module
    fun init(ctx: &mut TxContext) {
        init_module(ctx);
    }

    fun init_module(ctx: &mut TxContext) {
        transfer::share_object(
            OpenTopicStore {
                id: object::new(ctx),
                topics: table::new(ctx),
                comments: table::new(ctx),
                sequence: 0,
            }
        )
    }

    // new topic
    public fun new_topic(
        title: String,
        detail: String,
        format: String,
        category: String,
        photos: vector<vector<u8>>,
        author_name: String,
        ctx: &mut TxContext,
    ): Topic {
        let author = tx_context::sender(ctx);
        let created_at = tx_context::epoch(ctx);

        let content = base::new_rich_text(detail, format);

        let topic = Topic {
            id: object::new(ctx),
            title,
            content,
            category,
            photos,
            events: vector::empty<TopicEvent>(),
            author,
            author_name,
            created_at,
        };

        emit(TopicCreatedEvent {
            topic_id: object::id(&topic),
            title,
            content: base::new_rich_text(detail, format),
            category,
            photos,
            // events: vector::empty<TopicEvent>(),
            author,
            author_name,
            created_at,
        });

        topic
    }

    public entry fun create_topic_store(title: String, ctx: &mut TxContext) {
        let author = tx_context::sender(ctx);

        let tb = TopicStore {
            id: object::new(ctx),
            title,
            topics: table::new<ID, Topic>(ctx),
            topics_listed: table::new<ID, u64>(ctx),
        };

        transfer::transfer(tb, author);
    }

    public entry fun create_topic(
        my_store: &mut TopicStore,
        title: String,
        detail: String,
        format: String,
        category: String,
        photos: vector<vector<u8>>,
        author_name: String,
        ctx: &mut TxContext,
    ) {
        // let author = tx_context::sender(ctx);
        let topic = new_topic(title, detail, format, category, photos, author_name, ctx);

        // let stores = TopicStore {
        //     id: object::new(ctx),
        //     title,
        //     topics: table::new<ID, Topic>(ctx),
        //     topics_listed: table::new<ID, u64>(ctx),
        // };

        table::add(&mut my_store.topics, object::id(&topic), topic);

        // transfer::transfer(stores, author);
    } 

    // list topic in open store
    public entry fun list_topic(
        open_store: &mut OpenTopicStore,
        my_store: &mut TopicStore,
        topic: &Topic,
    ) {
        let inner_id = object::id(topic);
        open_store.sequence = open_store.sequence + 1;
        table::add(&mut open_store.topics, open_store.sequence, inner_id);
        table::add(&mut my_store.topics_listed, inner_id, open_store.sequence);
    }

    public entry fun create_topic_and_list(
        open_store: &mut OpenTopicStore,
        my_store: &mut TopicStore,
        title: String,
        detail: String,
        format: String,
        category: String,
        photos: vector<vector<u8>>,
        author_name: String,
        ctx: &mut TxContext,
    ) {
        // let author = tx_context::sender(ctx);
        let topic = new_topic(title, detail, format, category, photos, author_name, ctx);

        let topic_inner_id = object::id(&topic);

        list_topic(open_store, my_store, &topic);

        table::add(&mut my_store.topics, topic_inner_id, topic);  
        
    }
    
    public entry fun unlist_topic(
        open_store: &mut OpenTopicStore,
        my_store: &mut TopicStore,
        topic_inner_id: ID,
    ) {

        if (table::contains(&my_store.topics_listed, topic_inner_id)) {
            let idx = table::remove(&mut my_store.topics_listed, topic_inner_id);
            table::remove(&mut open_store.topics, idx);   
        }       
    }

    public entry fun update_topic(
        topic: &mut Topic,
        title: String,
        detail: String,
        format: String,
        category: String,
        photos: vector<vector<u8>>,
        author_name: String,
    ) {
        let content = base::new_rich_text(detail, format);
        topic.title = title;
        topic.content = content;
        topic.category = category;
        topic.photos = photos;
        topic.author_name = author_name;

        emit(TopicUpdatedEvent {
            topic_id: object::id(topic),
            title,
            content,
            category,
            photos,
            author_name,
            created_at: topic.created_at
        })
    }

    public fun delete_topic(
        topic: Topic
    ) {
        let Topic { id, title: _, content: _, category: _, photos: _, events: _, author: _, author_name: _, created_at: _ } = topic;
        object::delete(id);
    }

    public entry fun delete_topic_in_store(
        open_store: &mut OpenTopicStore,
        my_store: &mut TopicStore,
        topic_inner_id: ID,
    ) {
        assert!(table::contains(&my_store.topics, topic_inner_id), ENOT_FOUND);

        unlist_topic(open_store, my_store, topic_inner_id);
        let topic = table::remove(&mut my_store.topics, topic_inner_id);
        delete_topic(topic);   
    }

    public entry fun add_topic_comment(open_store: &mut OpenTopicStore, topic_idx: u64, detail: String, format: String, ctx: &mut TxContext) {

        assert!(table::contains(&open_store.topics, topic_idx), ENOT_FOUND);

        let content = base::new_rich_text(detail, format);
        let topic_id = table::borrow(&open_store.topics, topic_idx);
        let comment = comment::new_comment(*topic_id, content, ctx);

        transfer::transfer(comment, tx_context::sender(ctx));
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

    public fun events(t: &Topic): vector<TopicEvent> {
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

    // get the open topic store sequnece 
    public fun get_open_store_sequence(stores: &OpenTopicStore): u64 {
        stores.sequence
    }

    public fun get_latest_topic_id_from_open_store(store: &OpenTopicStore, idx: u64): &ID {
        table::borrow(&store.topics, idx)
    }

    public fun get_topic_from_topic_store(store: &TopicStore, inner_id: ID): &Topic {
        table::borrow(&store.topics, inner_id)
    }

    public fun is_empty_open_store(store: &OpenTopicStore): bool {
        table::is_empty(&store.topics)
    }

    public fun is_empty_topic_store(store: &TopicStore): bool {
        table::is_empty(&store.topics)
    }

    public fun listed_contains(store: &TopicStore, inner_id: ID): bool {
        table::contains(&store.topics, inner_id)
    }

    #[test_only]
    public fun init_test(ctx: &mut TxContext) {
        init_module(ctx);
    }
}