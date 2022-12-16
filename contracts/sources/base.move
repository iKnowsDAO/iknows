
module iknows::base {

    use std::string::{String};

    struct RichText has store, copy, drop {
        detail: String,
        format: String,
    }

    public fun new_rich_text(detail: String, format: String): RichText {
        RichText { detail, format }
    }
}
