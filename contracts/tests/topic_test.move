
module iknows::topic_tests {

    // #[test_only]
    // use sui::table;

    #[test_only]
    use std::string::{Self, utf8};

    #[test_only]
    use std::vector;

    // #[test_only]
    // use sui::tx_context::{Self, TxContext};

    #[test_only]
    use sui::test_scenario::{Self};

    #[test_only]
    use iknows::topic::{Self, init_test, TopicStore, OpenTopicStore};

    #[test]
    fun create_store_and_topic_and_list_should_work() {

        let user_addr = @0x008;

        let scenario_val = test_scenario::begin(user_addr);
        let scenario = &mut scenario_val;

        let my_store_name = string::utf8(b"my topic store");
        let title = utf8(b"topic title");
        let detail = utf8(b"topic detail");
        let format = utf8(b"topic format");
        let category = utf8(b"topic cateogory");
        let photos = vector::empty();
        let author = utf8(b"author");

        // init module, open stores
        let ctx = test_scenario::ctx(scenario);
        init_test(ctx);

        // create my topic store
        test_scenario::next_tx(scenario, user_addr);
        {
            let ctx = test_scenario::ctx(scenario);
            topic::create_topic_store(my_store_name, ctx);
        };

        // create topic and list
        test_scenario::next_tx(scenario, user_addr);
        {
            let open_store = test_scenario::take_shared<OpenTopicStore>(scenario);
            let my_store = test_scenario::take_from_sender<TopicStore>(scenario);
            let ctx = test_scenario::ctx(scenario);
            topic::create_topic_and_list(&mut open_store, &mut my_store, title, detail, format, category, photos, author, ctx);

            test_scenario::return_to_sender(scenario, my_store);
            test_scenario::return_shared<OpenTopicStore>(open_store);
        };

        // check the topic
        test_scenario::next_tx(scenario, user_addr);
        {
            let open_store = test_scenario::take_shared<OpenTopicStore>(scenario);
            let my_store = test_scenario::take_from_sender<TopicStore>(scenario);
            let open_sequence = topic::get_open_store_sequence(&open_store);
            let topic_inner_id = topic::get_latest_topic_id_from_open_store(&open_store, open_sequence);
            let topic = topic::get_topic_from_topic_store(&my_store, *topic_inner_id);
            let title1 = topic::title(topic);
            assert!( title1 == title, 0);

            test_scenario::return_to_sender(scenario, my_store);
            test_scenario::return_shared<OpenTopicStore>(open_store);
        };

        // unlist and delete topc
        test_scenario::next_tx(scenario, user_addr);
        {
            let open_store = test_scenario::take_shared<OpenTopicStore>(scenario);
            let my_store = test_scenario::take_from_sender<TopicStore>(scenario);
            let open_sequence = topic::get_open_store_sequence(&open_store);
            let topic_inner_id = topic::get_latest_topic_id_from_open_store(&open_store, open_sequence);
            topic::delete_topic_in_store(&mut open_store, &mut my_store, *topic_inner_id);

            test_scenario::return_to_sender(scenario, my_store);
            test_scenario::return_shared<OpenTopicStore>(open_store);
        };

        // check open store and topic is empty
        test_scenario::next_tx(scenario, user_addr);
        {
            let open_store = test_scenario::take_shared<OpenTopicStore>(scenario);
            let my_store = test_scenario::take_from_sender<TopicStore>(scenario);

            assert!(topic::is_empty_open_store(&open_store), 0);
            assert!(topic::is_empty_topic_store(&my_store), 0);

            test_scenario::return_to_sender(scenario, my_store);
            test_scenario::return_shared<OpenTopicStore>(open_store);
        };

        test_scenario::end(scenario_val);
    }
}