load 'encoder.ijs'
load 'utils.ijs'


gelu =: {{ -: y * >: 7&o. (%: 2p_1) * y + 0.044715 * y^3 }}

softmax =: {{ (% +/) ^ (- >./) y }}"1

layer_norm =: 3 : 0
  'x g b' =. y
  (b + g * [: (% [: %: 1e_5 + (+/%#)@:*:) (- +/%#))"1 x
)

mp =: +/ . *

linear =: 3 : 0
  'x w b' =. y
  b +"1 x mp w
)

ffn =: 3 : 0
  'x c_fc c_proj' =. y
  linear (gelu linear x ; c_fc) ; c_proj
)

attention =: 3 : 0
  'mask q k v' =. y
  v mp~ softmax mask + q mp (|: k) % %: {:$q
)

mha =: 3 : 0
  'x n_head c_attn c_proj' =. y
  x =. linear x ; c_attn

  d_head =. ({:$x) % 3 * n_head
  qkv_heads =. |: (3,n_head) $ (-d_head) <@|:\ |: x         NB. output (n_head, 3) of boxed (seq_len, d_head)
  causal_mask =. _1e10 * </~ i. {.$x
  out_heads =. ([: attention causal_mask ; ])"1 qkv_heads   NB. output (n_head, seq_len, d_head)
  linear (,/"2 ] 1 0 2 |: out_heads) ; c_proj
)

transformer_block =: 3 : 0
  'x n_head mlp attn ln_1 ln_2' =. y
  x =. x + mha (layer_norm x ; ln_1) ; n_head ; attn
  x =. x + ffn (layer_norm x ; ln_2) ; mlp
)

gpt2 =: 3 : 0
  'inputs n_head wte wpe blocks ln_f' =. y
  inputs =. inputs {.~ - (#inputs) <. {.$wpe   NB. Crop to n_ctx
  x =. (inputs { wte) + (# inputs) {. wpe
  x =. > ([: transformer_block ] ; n_head ; [)each/ |. x ; blocks
  wte mp {: layer_norm x ; ln_f                NB. For efficiency, only unembed the last token
)

generate =: 3 : 0
  'inputs params n_head n_tokens_to_generate' =. y
  for. i. n_tokens_to_generate do.
    logits =. gpt2 inputs ; n_head ; params
    next_id =. (i. >./) logits
    inputs =. inputs , next_id
    stderr decode__encoder next_id    NB. Use stderr because it's unbuffered
  end.
  (-n_tokens_to_generate) {. inputs
)


model_data =: a:
encoder =: MODELS_DIR conew 'encoder'

model =: 3 : 0
  model_data =: load_model y
  empty ''
)

gen =: 40&$: : (4 : 0)
  if. model_data -: a: do.
    echo 'First, load a model with `model ''SIZE''` (124M, 355M, 774M, 1558M)'
    return.
  end.

  'params n_ctx n_head' =. model_data
  input_ids =. encode__encoder y
  output_ids =. generate input_ids ; params ; n_head ; x
  output_text =. decode__encoder output_ids
)

echo 'Load (or switch) model with `model ''SIZE''` (124M, 355M, 774M, 1558M)'
echo 'Then generate with [tokens to gen (default: 40)] gen ''PROMPT'''
