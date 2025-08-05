#!/usr/bin/env python
"""
Merge LoRA weights into google/gemma-3n-e2b-it and export an INT-4 TFLite.
Tested with:
  • ai-edge-torch 0.4.0
  • torch-xla 2.5.0   • torch 2.5.0
  • tensorflow-cpu 2.19.0
  • protobuf 3.20.3
  • jax 0.5.1 / jaxlib 0.5.1 (CPU wheels)
"""
import argparse, pathlib, torch
from peft import PeftModel
from transformers import AutoModelForImageTextToText, AutoTokenizer

# ── helpers ──────────────────────────────────────────────────────────────
def _hidden(cfg):                       # Gemma-3n nests hidden_size
    return getattr(cfg, "hidden_size",
                   getattr(getattr(cfg, "text_config", None), "hidden_size"))

def merge_lora(base_id, lora_dir):
    base = AutoModelForImageTextToText.from_pretrained(
        base_id, torch_dtype=torch.float16, trust_remote_code=True)
    return PeftModel.from_pretrained(base, lora_dir).merge_and_unload().eval()

def export_int4(model, out_file, prefill, kv_len):
    import ai_edge_torch
    from ai_edge_torch.quantize.quant_config import QuantRecipes    # ← new
    ids = torch.zeros(1, 1, dtype=torch.int32)
    kv  = torch.zeros(1, 0, _hidden(model.config), dtype=torch.float16)
    qc  = QuantRecipes.dynamic_int4()                                # ← new
    tfl = ai_edge_torch.convert(model, (ids, kv), quant_config=qc)
    tfl.export(str(out_file))

# ── CLI ───────────────────────────────────────────────────────────────────
def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--lora_ckpt", required=True)
    ap.add_argument("--output_dir", required=True)
    ap.add_argument("--base_id", default="google/gemma-3n-e2b-it")
    ap.add_argument("--prefill_seq_lens", type=int, default=1024)
    ap.add_argument("--kv_cache_max_len", type=int, default=2048)
    args = ap.parse_args()

    out = pathlib.Path(args.output_dir).expanduser(); out.mkdir(parents=True, exist_ok=True)
    print("▶  Merging LoRA …")
    model = merge_lora(args.base_id, args.lora_ckpt)

    print("▶  Exporting INT-4 TFLite …")
    export_int4(model, out/"gemma3n_e2b_int4.tflite",
                args.prefill_seq_lens, args.kv_cache_max_len)

    print("▶  Saving tokenizer …")
    AutoTokenizer.from_pretrained(args.base_id, trust_remote_code=True)\
                 .save_pretrained(out)
    print("✅  Done →", out/"gemma3n_e2b_int4.tflite")

if __name__ == "__main__":
    main()
