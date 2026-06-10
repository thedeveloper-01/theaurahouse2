import { IsString, IsOptional, IsIn } from 'class-validator';

export class CreatePostDto {
  @IsString()
  @IsOptional()
  text?: string;

  @IsString()
  @IsOptional()
  @IsIn(['public', 'private', 'friends'])
  privacy?: string;
}

