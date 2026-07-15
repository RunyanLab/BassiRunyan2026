import os
import scipy.io
import argparse

def generate_batch_script(array_size, begin, save_string_glm, save_string_imaging, decoder_type, split = None):
    # Map decoder type number to string
    decoder_map = {
        1: "outcome",
        2: "choice",
        3: "sound_category", 
        4: "photostim"
    }
    decoder_strs = [decoder_map[dt] for dt in decoder_type]
    decoder_str_joined = '_'.join(decoder_strs)  #(str(dt) for dt in decoder_type)
    
    # Create continuous array range and split mapping
    if split is not None:
        split_indices = ''.join(map(str, split))
        array_range = f"0-{len(split)-1}"
        # Create Bash array of actual split numbers
        splits_array = "(" + " ".join(map(str, split)) + ")"
    else:
        array_range = "0-24"
        splits_array = "({0..24})"
        split_indices = "0-24"

    e_name = f"arrayjob_SVMdecoder_subsampled_{save_string_imaging}_{decoder_str_joined}_%a.err"
    o_name = f"arrayjob_SVMdecoder_subsampled_{save_string_imaging}_{decoder_str_joined}_%a.out"

    script_content = f"""#!/bin/bash
#SBATCH --qos=htc-htc-crunyan-n
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cluster=htc
#SBATCH --mem=48G
#SBATCH --time=3-00:00:00
#SBATCH --job-name=run_glm
#SBATCH --output=glmscript.out
#SBATCH -J arrayjob
#SBATCH --array={array_size}
#SBATCH -e {e_name}
#SBATCH -o {o_name}
#SBATCH --mail-user=cdb66@pitt.edu
#SBATCH --mail-type=END
#SBATCH --no-requeue
#SBATCH --begin={begin}
# Load Modules
module load matlab/R2023a

# Define array of actual split numbers
splits={splits_array}

# Get actual split number from array
split_num=${{splits[$SLURM_ARRAY_TASK_ID]}}

# # Get actual split number (1-based)
# split_num=$((SLURM_ARRAY_TASK_ID + 1))

set -v
matlab -nodisplay -r "addpath(genpath('/ihome/crunyan/cdb66/Code/SVM')); wrapper_SVM_cluster_subsample_neurons($split_num,'{save_string_glm}','{save_string_imaging}', {decoder_type}); exit;" 
"""

    # Create directories if they don't exist
    save_path = 'V:/Connie/results/SVM' #os.path.join(save_string_glm, experiment, date)
    os.makedirs(save_path, exist_ok=True)
    script_file = os.path.join(save_path, f'glm_SVMdecoder_subsampled_{save_string_imaging}_{decoder_str_joined}.slurm')
    print(save_path)
    with open(script_file, 'w') as file:
        file.write(script_content)

def convert_to_unix_line_endings(file_path):
    with open(file_path, 'r', newline='', encoding='utf-8') as file:
        content = file.read()
    content = content.replace('\r\n', '\n')
    with open(file_path, 'w', newline='', encoding='utf-8') as file:
        file.write(content)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Generate batch scripts for datasets.')
    parser.add_argument('--mat_file', required=True, help='Path to the MATLAB file containing dataset info.')
    parser.add_argument('--begin', required=True, help='Job start time.')
    parser.add_argument('--save_string_glm', required=True, help='GLM save string.')
    parser.add_argument('--save_string_imaging', required=True, help='Imaging save string.')
    parser.add_argument('--decoder_type', nargs='+', type=int, required=True, 
                       help='List of decoder types: 3=sounds, 4=photostim, 2=choice, 1=outcome. Example: --decoder_types 2 3 4')
    parser.add_argument('--dataset_index', nargs='+', type=int, help='Specific dataset indeces to process (optional)')
    args = parser.parse_args()
    
    # Load MATLAB structure
    mat = scipy.io.loadmat(args.mat_file)
    
    # Get total number of datasets
    total_datasets = len(mat['info']['mouse_date'][0][0][0])
    
    save_string = 'V:/Connie/results/SVM'

    decoder_map = {
        1: "outcome",
        2: "choice",
        3: "sound_category", 
        4: "photostim"
    }
    decoder_strs = [decoder_map[dt] for dt in args.decoder_type]
    decoder_str_joined = '_'.join(decoder_strs)  #join(str(dt) for dt in args.decoder_type)
    
    
    if args.dataset_index is not None:
        dataset_indices = [str(i-1) for i in args.dataset_index]
        array_range = ','.join(dataset_indices)
        array_range = f'0-{len(dataset_indices)-1}'
        print(array_range)
        generate_batch_script(array_range , args.begin,  args.save_string_glm, args.save_string_imaging, args.decoder_type, args.dataset_index)
        
        saved_slurm = os.path.join(save_string, f'glm_SVMdecoder_subsampled_{args.save_string_imaging}_{decoder_str_joined}.slurm')
        convert_to_unix_line_endings(saved_slurm)