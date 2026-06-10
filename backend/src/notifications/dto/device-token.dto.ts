import { IsString, IsNotEmpty, IsIn, IsOptional } from 'class-validator';

export class RegisterDeviceTokenDto {
  @IsString()
  @IsNotEmpty()
  token: string;

  @IsString()
  @IsIn(['android', 'ios', 'web'])
  platform: 'android' | 'ios' | 'web';

  @IsString()
  @IsOptional()
  deviceId?: string;

  @IsString()
  @IsOptional()
  appVersion?: string;
}

export class DeleteDeviceTokenDto {
  @IsString()
  @IsNotEmpty()
  token: string;
}

