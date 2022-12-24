
module iknows::topic_tests {

    #[test_only]
    use sui::object::{Self, ID};

    #[test_only]
    use std::string::{utf8};

    #[test_only]
    use std::vector;

    #[test_only]
    use std::option::{Self, Option};

    // #[test_only]
    // use sui::tx_context::{Self, TxContext};

    #[test_only]
    use sui::test_scenario::{Self};

    #[test_only]
    use iknows::topic_board::{Self as board, Board, init_test};
    use iknows::topic::{Self, Topic};

    #[test]
    fun create_store_and_topic_and_list_should_work() {

        let user_addr = @0x008;

        let scenario_val = test_scenario::begin(user_addr);
        let scenario = &mut scenario_val;

        let title = utf8(b"topic title");
        let detail = utf8(b"topic detail");
        let format = utf8(b"topic format");
        let category = utf8(b"topic cateogory");
        let photos = vector::empty();
        let author = utf8(b"author");

        let topic_opt: Option<ID> = option::none();

        // init module, open stores
        let ctx = test_scenario::ctx(scenario);
        init_test(ctx);

        // create topic and list
        test_scenario::next_tx(scenario, user_addr);
        {
            let board = test_scenario::take_shared<Board<Topic>>(scenario);
            
            let ctx = test_scenario::ctx(scenario);
            let topic1 = topic::new_topic(title, detail, format, category, photos, author, ctx);

            option::fill(&mut topic_opt, object::id(&topic1));

            board::list_topic(&mut board, topic1, 0, ctx);

            test_scenario::return_shared<Board<Topic>>(board);
        };

        // check the topic
        test_scenario::next_tx(scenario, user_addr);
        {
            let board = test_scenario::take_shared<Board<Topic>>(scenario);
            assert!(board::get_total(&board) == 1, 0);
            assert!(board::get_sequence(&board) == 10001, 0);
            test_scenario::return_shared<Board<Topic>>(board);
        };

        // unlist and delete topc
        test_scenario::next_tx(scenario, user_addr);
        {
            let board = test_scenario::take_shared<Board<Topic>>(scenario);
            let ctx = test_scenario::ctx(scenario);
            // TODO How to get topic id
            let topic_id = option::extract(&mut topic_opt);
            board::unlist_and_take_topic(&mut board, topic_id, ctx);

            test_scenario::return_shared<Board<Topic>>(board);
        };

        // check open store and topic is empty
        test_scenario::next_tx(scenario, user_addr);
        {
            let board = test_scenario::take_shared<Board<Topic>>(scenario);
            let topic1 = test_scenario::take_from_sender<Topic>(scenario);

            assert!(board::get_total(&board) == 0, 0);
            assert!(topic::title(&topic1) == title, 0);

            test_scenario::return_to_sender(scenario, topic1);
            test_scenario::return_shared<Board<Topic>>(board);
        };

        test_scenario::end(scenario_val);
    }
    
}