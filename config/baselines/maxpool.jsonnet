local model_name = std.extVar('TRANSFORMER_MODEL');
local train_data = std.extVar('FVR_TRAIN_PATH');
local dev_data = std.extVar('FVR_VALID_PATH');
local hidden_dimension = 768;
local num_labels = 3;

{
    "train_data_path": train_data,
    "validation_data_path": dev_data,
    "dataset_reader": {
        "type": "fever_kgat_fmt_json_reader",
        "max_sentences_to_keep": 20,
        "num_examples_to_print": 5,
        "prepend_page_name": true,
        "instance_generator": {
            "type": "sep_instance_generator",
            "max_sequence_length": 256,
            "tokenizer_model_name_or_path": model_name,
            "token_indexers": {
                "tokens": {
                    "type": "pretrained_transformer",
                    "model_name": model_name,
                    "namespace": "tokens"
                }
            }
        },
    },
    "model": {
        "type": "global_trans2sec2vec_model",
        "transformer_model": model_name,
        "index": "tokens",
        "dropout": 0.1,
        "claim_encoder": {
            "type": "max_pooler"
        },
        "classification_layer": {
            "input_dim": hidden_dimension,
            "num_layers": 1,
            "hidden_dims": [num_labels],
            "activations": ["linear"],
            "dropout": [0]
        },
        "evaluator" : {
            "type" : "named_classification_multiclass_metrics_ce_loss",
            "num_labels": num_labels,
            "class_name_list": ["s", "r", "n"],
            "evaluator_name": "g",
            "brief_report": true
        }
    },

    "data_loader": {
        "batches_per_epoch": 8000,
        "batch_sampler": {
            "type": "bucket",
            "batch_size": 4
        }
    },

    "validation_data_loader": {
        "batch_sampler": {
            "type": "bucket",
            "batch_size": 42
        }
    },

    "trainer": {
        "optimizer": {
            "type": "huggingface_adamw",
            "lr": 2e-5,
            "weight_decay": 0.01,
            "parameter_groups": [
              [["bias", "LayerNorm.bias", "LayerNorm.weight", "layer_norm.weight"], {"weight_decay": 0.0}]
            ]
        },
        "num_gradient_accumulation_steps": 16,
        "validation_metric": "+g_a",
        "learning_rate_scheduler": {
            "type": "slanted_triangular",
            "num_epochs": 14
        },
        "num_epochs": 14,
        "checkpointer": {
            "num_serialized_models_to_keep": 1
        },
        "callbacks": [
            {
                "type": "tensorboard",
                "batch_size_interval": 10,
                "summary_interval": 10,
                "should_log_learning_rate": true,
                "should_log_parameter_statistics": true,
            },
        ],
        "cuda_device": 0,

    }

}
