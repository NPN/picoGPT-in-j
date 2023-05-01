require 'convert/pjson'

MODELS_DIR =: 'models'


file_exists =: 3 : 0
  if. -. fexist y do.
    echo 'File does not exist: ' , y
    assert. fexist y
  end.
)

load_safetensors =: 3 : 0
  fopen  =. 1!:21
  fclose =. 1!:22
  to_i32 =. _2&(3!:4)
  to_f32 =. _1&(3!:5)

  file_exists y
  ckpt =. fopen <y

  echo '  Processing header'
  NB. The header size is a u64, but it's unlikely to exceed 2^31 = 2 GiB, so to_i32 is okay
  NB. to_i64 =: _3&(3!:4) would be better, but it's not supported by 32-bit J
  header_size =. to_i32 fread ckpt ; 0 4
  header =. |: (#~ (<'__metadata__') ~: {."1) dec_pjson_ fread ckpt ; 8,header_size
  names =. {. header
  dtype_shape_offset =. {:&.|: > {: header
  NB. For simplicity, we only support F32
  assert. (< 'F32') *./@:= {."1 dtype_shape_offset

  echo '  Reading data'
  header_offset =. 8 + header_size
  read =. [: fread ckpt ; (header_offset , 0) + ([ , -~)/
  tensors =. ($ to_f32@read)each/"1 }."1 dtype_shape_offset

  fclose ckpt

  names ,&< tensors
)

load_model =: 3 : 0
  path =. MODELS_DIR , '/' , y

  echo 'Loading model: ', y
  'names tensors' =. load_safetensors path , '/model.safetensors'
  echo 'Done.'

  file_exists path , '/config.json'
  config =. |: dec_pjson_ fread path , '/config.json'
  'n_layer n_ctx n_head' =. > ({: config) {~ ({. config) i. 'n_layer' ; 'n_ctx' ; 'n_head'

  wb =. ,&'.weight' <@; ,&'.bias'
  mlp  =. (wb '.mlp.c_fc')    <@, wb '.mlp.c_proj'
  attn =. (wb '.attn.c_attn') <@, wb '.attn.c_proj'
  ln_1 =.  wb '.ln_1'
  ln_2 =.  wb '.ln_2'
  block =. mlp , attn , ln_1 , ln_2

  blocks =. (i. n_layer) ('h.' , ":@[ , ]) L:0"0 <block
  model =. 'wte.weight' ; 'wpe.weight' ; blocks ; wb 'ln_f'
  model =. (tensors {::~ [: names&i. <) L:0 model
  model ; n_ctx ; n_head
)
