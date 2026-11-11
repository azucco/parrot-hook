# parrot-hook

A prompt hook for AI coding agents: end your message with `-parrot` and the agent only restates what it understood — no tools, no solutions.

## Why

When brainstorming, you often write a long, unfiltered stream of consciousness to explain a problem. It can be messy or even contradictory. If the agent jumps straight into editing code or proposing a solution, it may be acting on a misunderstanding.

`-parrot` adds a checkpoint: the agent repeats back what it understood, you confirm or correct it, and only then do you move on.

## Example

**You:**

> we need to rework how coupons work at checkout. right now an order can have
> at most one coupon: there's a `coupon_id` column on `orders` and
> `CouponService::apply()` takes the cart and a single coupon. marketing wants
> stackable coupons, so I'm thinking of a pivot table `order_coupons` with
> `order_id`, `coupon_id`, the discount amount actually applied, and the
> position in which it was applied, so we can show the breakdown on the
> invoice. the order matters: percentage coupons first, then fixed-amount
> ones, otherwise the total changes depending on what the customer typed
> first. max two coupons per order, but the loyalty coupon doesn't count
> towards the limit. some coupons are flagged `exclusive` and can't be
> combined with anything. the total discount can never bring the order below
> shipping costs. I'd keep the `apply()` signature as it is, because the
> mobile app and the admin panel both call it, and I don't want to touch
> those right now. actually, forget the pivot table: we never query coupons
> by order, we only display them, so a JSON column `applied_coupons` on
> `orders` is enough and much simpler. products already on sale shouldn't
> get further discounts, but I'm not sure that's true for the loyalty
> coupon -parrot

**Agent:**

> Here's what I understood:
>
> - **Current state:** one coupon per order (`orders.coupon_id`);
>   `CouponService::apply()` takes the cart and a single coupon.
> - **Goal:** stackable coupons, as requested by marketing.
> - **Data model:** a JSON column `applied_coupons` on `orders`, to show the
>   breakdown on the invoice.
>   *You changed your mind here: you started with an `order_coupons` pivot
>   table, then dropped it because coupons are only displayed, never
>   queried by order. I'm going with the JSON column.*
> - **Business rules:**
>   - percentage coupons are applied before fixed-amount ones,
>     regardless of input order;
>   - max two coupons per order, the loyalty coupon excluded from the count;
>   - `exclusive` coupons can't be combined with any other;
>   - the total discount can't bring the order below shipping costs;
>   - products already on sale get no further discount.
> - **Constraint:** the `apply()` signature stays unchanged, since the mobile
>   app and the admin panel depend on it.
>
> **What I inferred:**
> - `orders.coupon_id` becomes redundant once `applied_coupons` exists.
> - The "below shipping costs" floor applies to the order total after all
>   coupons, not to each coupon individually.
>
> **Open questions:**
> - Should each entry in `applied_coupons` store the coupon id, the applied
>   amount and the application position, as needed for the invoice
>   breakdown?
> - `apply()` takes a single coupon, but the new logic needs the whole set
>   to decide order, limits and exclusivity: how should multiple coupons
>   reach it without changing the signature?
> - Does an `exclusive` coupon also block the loyalty coupon?
> - Do on-sale products receive the loyalty discount or not? You left this
>   open.
>
> Did I get it right?

The agent does not read or edit files, run commands, or propose solutions on that turn.

## Requirements

- [Claude Code](https://code.claude.com)
- `bash`
- [`jq`](https://jqlang.org)

## Installation (Claude Code)

1. Copy the script:

   ```bash
   mkdir -p ~/.claude/hooks
   cp parrot.sh ~/.claude/hooks/parrot.sh
   chmod +x ~/.claude/hooks/parrot.sh
   ```

2. Register the hook in `~/.claude/settings.json` (merge it with any existing `hooks` section):

   ```json
   {
     "hooks": {
       "UserPromptSubmit": [
         {
           "hooks": [
             { "type": "command", "command": "bash ~/.claude/hooks/parrot.sh" }
           ]
         }
       ]
     }
   }
   ```

3. Start a new Claude Code session.

## Usage

Put `-parrot` at the very end of your message, separated by a space or a newline.

- Case-insensitive: `-Parrot` works too.
- Trailing spaces and newlines are ignored.
- `-parrot` in the middle of a message, or glued to another word (`x-parrot`), does nothing.

## How it works

Claude Code runs the `UserPromptSubmit` hook every time you press Enter. If the message ends with `-parrot`, the script returns an `additionalContext` instruction that tells the agent, for that turn only, to restate your message and do nothing else. Otherwise the script exits silently.

## Limitations

The hook adds an instruction; it does not technically block tool use. In practice the instruction is explicit enough to be followed, but it is not a hard guarantee.

## Other agents

Only Claude Code is supported and tested. The script is small and can be adapted to other agents that have a similar prompt hook:

| Agent | Event | Status |
|---|---|---|
| Claude Code | `UserPromptSubmit` | Supported |
| Codex CLI | `UserPromptSubmit` | Likely compatible (same JSON output), untested |
| Gemini CLI | `BeforeAgent` | Should work after changing `hookEventName` in the output, untested |
| Cursor | `beforeSubmitPrompt` | Not possible today: the hook can only allow or block a prompt, not add context |

Contributions for other agents are welcome.

## License

[MIT](LICENSE) © azucco
