class Gemma3nForTFLite(torch.nn.Module):
    """A wrapper for the Gemma3nForConditionalGeneration model for TFLite conversion."""
    def __init__(self, model_path):
        super().__init__()
        print(f"Loading merged model for re-authoring from: {model_path}")
        # Load the model's configuration first
        config = AutoConfig.from_pretrained(model_path, trust_remote_code=True)
        # Load the full model using the config
        self.gemma_model = AutoModelForCausalLM.from_pretrained(
            model_path,
            config=config,
            torch_dtype=torch.float16,
            trust_remote_code=True,
        ).eval()
        print("Model loaded in wrapper.")

    def text_prefill(self, input_ids: torch.Tensor):
        """
        Forward pass for the text prefill stage.
        This takes token IDs and produces logits and the Key-Value (KV) cache.
        """
        outputs = self.gemma_model(
            input_ids=input_ids,
            use_cache=True
        )
        return outputs.logits, outputs.past_key_values

    def text_decode(self, input_ids: torch.Tensor, past_key_values):
        """
        Forward pass for the text decode (token generation) stage.
        This takes a single new token and the previous KV cache.
        """
        outputs = self.gemma_model(
            input_ids=input_ids,
            past_key_values=past_key_values,
            use_cache=True
        )
        return outputs.logits, outputs.past_key_values

    def vision_encode(self, pixel_values: torch.Tensor):
        """
        Forward pass for the vision encoder.
        This takes image pixel values and produces image embeddings.
        This calls the model's vision_encoder component directly.
        """
        # The `vision_encoder` is a specific attribute of the Gemma3n model.
        if hasattr(self.gemma_model, 'vision_encoder'):
            return self.gemma_model.vision_encoder(pixel_values)
        else:
            raise AttributeError("Model does not have a 'vision_encoder' attribute.")

    def audio_encode(self, audio_values: torch.Tensor):
        """
        Forward pass for the audio encoder.
        This takes audio waveform/spectrogram and produces audio embeddings.
        This calls the model's audio_encoder component directly.
        """
        # The `audio_encoder` is a specific attribute of the Gemma3n model.
        if hasattr(self.gemma_model, 'audio_encoder'):
            return self.gemma_model.audio_encoder(audio_values)
        else:
            raise AttributeError("Model does not have a 'audio_encoder' attribute.")